#!/bin/bash
###############################################################################
# Run a Blockbridge simulator management node and 1 storage node for local host
# storage access only.
###############################################################################

###############################################################################
# configuration parameters. Set here or in environment.
###############################################################################

# management node simulator name
: ${BB_MN_SIM_NAME="bbsim-mn"}

# management node management port
: ${BB_MN_SSL_PORT=443}
: ${BB_MN_WEB_PORT=80}

# storage node simulator name
: ${BB_SN_SIM_NAME="bbsim-sn1"}

# run simulator in debug mode
#BB_DEBUG="--debug"

###############################################################################
# check parameters
###############################################################################
: ${BB_MN_SIM_NAME:?"BB_MN_SIM_NAME (management node simulator name) is not set"}
: ${BB_MN_SSL_PORT:?"BB_MN_SSL_PORT (management node management port) is not set"}
: ${BB_MN_WEB_PORT:?"BB_MN_WEB_PORT (management node web redirect) is not set"}
: ${BB_SN_SIM_NAME:?"BB_SN_SIM_NAME (storage node simulator name) is not set"}

###############################################################################
# run management node
###############################################################################
PARAMS=(--name "$BB_MN_SIM_NAME"        \
        --env BB_SIM_MODE="management"  \
        --privileged                    \
        --ulimit msgqueue=-1            \
        --publish $BB_MN_SSL_PORT:443   \
        --publish $BB_MN_WEB_PORT:80    \
        --detach)

echo -n "Starting management node: "
MN_CID=$(docker run "${PARAMS[@]}" blockbridge/simulator $BB_DEBUG)
if [ $? -ne 0 ]; then
    echo "Unable to start management node"
    exit 1
fi

if [ -z "$MN_CID" ]; then
    echo "Unable to find container-id for mn"
    exit 1
fi

echo $MN_CID

# wait for management node to boot
for (( i=0 ; $i < 30; i++ )); do
    BB_MN_API_KEY=$(docker exec $MN_CID cat /bb/etc/system.api.token 2>/dev/null)
    if [ $? -ne 0 ]; then
        # retry
        sleep 1
        continue
    fi

    if [ -z "$BB_MN_API_KEY" ]; then
        # retry
        sleep 1
        continue
    fi

    break
done

if [ $i -eq 30 ]; then
    echo "Failed to find API token from management node"
    exit 1
fi

###############################################################################
# run storage node
###############################################################################
PARAMS=(--name "$BB_SN_SIM_NAME"                    \
        --env BB_SIM_MODE="storage"                 \
        --env BLOCKBRIDGE_API_KEY="$BB_MN_API_KEY"  \
        --privileged                                \
        --ulimit msgqueue=-1                        \
        --ulimit memlock=-1                         \
        --link $BB_MN_SIM_NAME:mn                   \
        --detach)

echo -n "Starting storage node: "
docker run "${PARAMS[@]}" blockbridge/simulator $BB_DEBUG
if [ $? -ne 0 ]; then
    echo "Unable to start storage node"
    exit 1
fi
