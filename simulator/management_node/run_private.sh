#!/bin/bash
###############################################################################
# Run a Blockbridge simulator management node
###############################################################################

###############################################################################
# configuration parameters. Set here or in environment.
###############################################################################

# management node simulator name
: ${BB_MN_SIM_NAME="bbsim-mn"}

# management node management port
: ${BB_MN_SSL_PORT=443}
: ${BB_MN_WEB_PORT=80}

# run simulator in debug mode
#BB_DEBUG="--debug"

###############################################################################
# check parameters
###############################################################################
: ${BB_MN_SIM_NAME:?"BB_MN_SIM_NAME (management node simulator name) is not set"}
: ${BB_MN_SSL_PORT:?"BB_MN_SSL_PORT (management node management port) is not set"}
: ${BB_MN_WEB_PORT:?"BB_MN_WEB_PORT (management node web redirect) is not set"}

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
docker run "${PARAMS[@]}" blockbridge/simulator $BB_DEBUG
if [ $? -ne 0 ]; then
    echo "Unable to start management node"
    exit 1
fi
