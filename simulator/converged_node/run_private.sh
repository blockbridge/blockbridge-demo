#!/bin/bash
###############################################################################
# Run a Blockbridge simulator converged node with management and storage
# all-in-one for local host storage access only.
###############################################################################

###############################################################################
# configuration parameters. Set here or in environment.
###############################################################################

# converged node simulator name
: ${BB_SIM_NAME="bbsim-converged"}

# converged node management port
: ${BB_SSL_PORT=443}
: ${BB_WEB_PORT=80}

# run simulator in debug mode
#BB_DEBUG="--debug"

###############################################################################
# check parameters
###############################################################################
: ${BB_SIM_NAME:?"BB_SIM_NAME (converged node simulator name) is not set"}
: ${BB_SSL_PORT:?"BB_SSL_PORT (converged node management port) is not set"}
: ${BB_WEB_PORT:?"BB_WEB_PORT (management node web redirect) is not set"}

###############################################################################
# run converged node
###############################################################################
PARAMS=(--name "$BB_SIM_NAME"           \
        --env BB_SIM_MODE="converged"   \
        --privileged                    \
        --ulimit msgqueue=-1            \
        --ulimit memlock=-1             \
        --publish $BB_SSL_PORT:443      \
        --publish $BB_WEB_PORT:80       \
        --detach)

echo -n "Starting converged node: "
docker run "${PARAMS[@]}" blockbridge/simulator $BB_DEBUG
if [ $? -ne 0 ]; then
    echo "Unable to start converged node"
    exit 1
fi
