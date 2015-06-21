#!/bin/bash
###############################################################################
# Run a Blockbridge simulator management node with an IP address configured for 
# remote storage access.
###############################################################################

###############################################################################
# defines
###############################################################################
readonly BB_MN_INPUT_CHAIN="BLOCKBRIDGE_INPUT_MN"
readonly BB_MP_PORT="20400"
readonly BB_MLP_PORT="20300"

###############################################################################
# configuration parameters. Set here or in environment.
###############################################################################

# management node simulator name
: ${BB_MN_SIM_NAME="bbsim-mn"}

# management node management port
: ${BB_MN_SSL_PORT=443}
: ${BB_MN_WEB_PORT=80}

# management node IP address
: ${BB_MN_SIM_IP=""}

# run simulator in debug mode
#BB_DEBUG="--debug"

###############################################################################
# check parameters
###############################################################################
: ${BB_MN_SIM_NAME:?"BB_MN_SIM_NAME (management node simulator name) is not set"}
: ${BB_MN_SSL_PORT:?"BB_MN_SSL_PORT (management node management port) is not set"}
: ${BB_MN_WEB_PORT:?"BB_MN_WEB_PORT (management node web redirect) is not set"}
: ${BB_MN_SIM_IP:?"BB_MN_SIM_IP (management node IP address) is not set"}

###############################################################################
# firewall setup
###############################################################################
echo "Setting simulator firewall rules (may need sudo password)"

function add_firewall()
{
    command -v iptables >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Not modifying firewall rules; iptables command not found in path; remote connections may not work as expected"
        return
    fi

    sudo iptables -N $BB_MN_INPUT_CHAIN >/dev/null 2>&1
    set -e
    sudo iptables -A $BB_MN_INPUT_CHAIN -p tcp                             \
                                        --dst $BB_MN_SIM_IP                \
                                        --dport $BB_MN_SSL_PORT            \
                                        -j ACCEPT                          \
                                        -m comment                         \
                                        --comment "user management port"
    sudo iptables -A $BB_MN_INPUT_CHAIN -p tcp                             \
                                        --dst $BB_MN_SIM_IP                \
                                        --dport $BB_MN_WEB_PORT            \
                                        -j ACCEPT                          \
                                        -m comment                         \
                                        --comment "user management redirect"
    sudo iptables -A $BB_MN_INPUT_CHAIN -p tcp                             \
                                        --dst $BB_MN_SIM_IP                \
                                        --dport $BB_MP_PORT                \
                                        -j ACCEPT                          \
                                        -m comment                         \
                                        --comment "internode management"
    sudo iptables -A $BB_MN_INPUT_CHAIN -p tcp                             \
                                        --dst $BB_MN_SIM_IP                \
                                        --dport $BB_MLP_PORT               \
                                        -j ACCEPT                          \
                                        -m comment                         \
                                        --comment "internode management"
    sudo iptables -I INPUT -j $BB_MN_INPUT_CHAIN
    set +e
}

# add firewall rules
add_firewall
if [ $? -ne 0 ]; then
    echo "Setting firewall rules failed"
    exit 1
fi

###############################################################################
# run management node
###############################################################################
PARAMS=(--name "$BB_MN_SIM_NAME"                            \
        --env BB_SIM_MODE="management"                      \
        --env BB_SIM_IP="$BB_MN_SIM_IP"                     \
        --publish $BB_MN_SIM_IP:$BB_MN_SSL_PORT:443         \
        --publish $BB_MN_SIM_IP:$BB_MP_PORT:$BB_MP_PORT     \
        --publish $BB_MN_SIM_IP:$BB_MLP_PORT:$BB_MLP_PORT   \
        --privileged                                        \
        --ulimit msgqueue=-1                                \
        --detach)

echo -n "Starting management node: "
docker run "${PARAMS[@]}" blockbridge/simulator $BB_DEBUG
if [ $? -ne 0 ]; then
    echo "Unable to start management node"
    exit 1
fi
