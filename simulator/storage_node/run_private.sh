#!/bin/bash
###############################################################################
# Run a Blockbridge simulator storage node.
###############################################################################

###############################################################################
# configuration parameters. Set here or in environment.
###############################################################################

# management node simulator name
: ${BB_MN_SIM_NAME="bbsim-mn"}

# management node api key (pulls from local container if unspecified)
: ${BB_MN_API_KEY=""}

# storage node simulator name (defaults below if unspecified)
: ${BB_SN_SIM_NAME=""}

# run simulator in debug mode
#BB_DEBUG="--debug"

###############################################################################
# check parameters
###############################################################################
: ${BB_MN_SIM_NAME:?"BB_MN_SIM_NAME (management node simulator name) is not set"}

###############################################################################
# lookup API key from management node
###############################################################################
if [ -z "$BB_MN_API_KEY" ]; then
    for (( i=0 ; $i < 30; i++ )); do
        BB_MN_API_KEY=$(docker exec $BB_MN_SIM_NAME cat /bb/etc/system.api.token 2>/dev/null)
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
fi

###############################################################################
# set default name by looking up existing storage nodes names
###############################################################################
if [ -z "$BB_SN_SIM_NAME" ]; then
    SNCNT=0
    for CID in $(docker ps -q --filter "name=bbsim-sn*")
    do
        CNT=$(docker inspect --format '{{ .Name }}' $CID | sed "s/\/bbsim-sn\([0-9]*[^0-9]*\)$/\\1/")
        if [[ -n "$CNT" && $CNT > $SNCNT ]]; then
            SNCNT=$CNT
        fi
    done
    SNCNT=$(( $SNCNT + 1 ))
    BB_SN_SIM_NAME="bbsim-sn$SNCNT"
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
