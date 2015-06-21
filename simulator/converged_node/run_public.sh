#!/bin/bash
###############################################################################
# Run a Blockbridge simulator converged node with management and storage
# all-in-one with an IP address configured for remote storage access.
###############################################################################

###############################################################################
# defines
###############################################################################
readonly BB_MN_INPUT_CHAIN="BLOCKBRIDGE_INPUT_MN"
readonly BB_SN_INPUT_CHAIN="BLOCKBRIDGE_INPUT_SN"
readonly BB_MP_PORT="20400"
readonly BB_MLP_PORT="20300"

###############################################################################
# IP auto-detect
###############################################################################
function ip_detect()
{
    HOST_IP=$(ip -4 route get 1 | awk '{ print $NF; exit }')
    if [ -z "$HOST_IP" ]; then
        return
    fi
}

ip_detect

###############################################################################
# configuration parameters. Set here or in environment.
###############################################################################

# converged node simulator name
: ${BB_SIM_NAME="bbsim-converged"}

# management node management port
: ${BB_SSL_PORT=443}
: ${BB_WEB_PORT=80}

# management node IP address
: ${BB_SIM_IP="$HOST_IP"}

# run simulator in debug mode
#BB_DEBUG="--debug"

###############################################################################
# config check
###############################################################################
: ${BB_SIM_NAME:?"BB_SIM_NAME is not set"}
: ${BB_SIM_IP:?"BB_SIM_IP is not set"}
: ${BB_SSL_PORT:?"BB_SSL_PORT is not set"}
: ${BB_WEB_PORT:?"BB_WEB_PORT (management node web redirect) is not set"}

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


    # management rules
    sudo iptables -N $BB_MN_INPUT_CHAIN >/dev/null 2>&1
    set -e
    sudo iptables -A $BB_MN_INPUT_CHAIN -p tcp                              \
                                        --dst $BB_SIM_IP                    \
                                        --dport $BB_SSL_PORT                \
                                        -j ACCEPT                           \
                                        -m comment                          \
                                        --comment "user management port"
    sudo iptables -A $BB_MN_INPUT_CHAIN -p tcp                              \
                                        --dst $BB_SIM_IP                    \
                                        --dport $BB_WEB_PORT                \
                                        -j ACCEPT                           \
                                        -m comment                          \
                                        --comment "user management redirect"
    sudo iptables -A $BB_MN_INPUT_CHAIN -p tcp                              \
                                        --dst $BB_SIM_IP                    \
                                        --dport $BB_MP_PORT                 \
                                        -j ACCEPT                           \
                                        -m comment                          \
                                        --comment "internode management"
    sudo iptables -A $BB_MN_INPUT_CHAIN -p tcp                              \
                                        --dst $BB_SIM_IP                    \
                                        --dport $BB_MLP_PORT                \
                                        -j ACCEPT                           \
                                        -m comment                          \
                                        --comment "internode management"
    sudo iptables -I INPUT -j $BB_MN_INPUT_CHAIN
    set +e

    # storage rules
    sudo iptables -N $BB_SN_INPUT_CHAIN >/dev/null 2>&1
    set -e
    sudo iptables -A $BB_SN_INPUT_CHAIN -p tcp                              \
                                        --dst $BB_SIM_IP                    \
                                        --dport 3260                        \
                                        -j ACCEPT                           \
                                        -m comment                          \
                                        --comment "iscsi storage"
    sudo iptables -I INPUT -j $BB_SN_INPUT_CHAIN
    set +e
}

# add firewall rules
add_firewall
if [ $? -ne 0 ]; then
    echo "Setting firewall rules failed"
    exit 1
fi

###############################################################################
# run converged node
###############################################################################
PARAMS=(--name "$BB_SIM_NAME"                               \
        --env BB_SIM_MODE="converged"                       \
        --env BB_SIM_IP="$BB_SIM_IP"                        \
        --publish $BB_SIM_IP:$BB_SSL_PORT:443               \
        --publish $BB_SIM_IP:$BB_MP_PORT:$BB_MP_PORT        \
        --publish $BB_SIM_IP:$BB_MLP_PORT:$BB_MLP_PORT      \
        --publish $BB_SN_SIM_IP:3260:3260                   \
        --privileged                                        \
        --ulimit msgqueue=-1                                \
        --ulimit memlock=-1                                 \
        --detach)

echo -n "Starting converged node (using $BB_SIM_IP): "
docker run "${PARAMS[@]}" blockbridge/simulator $BB_DEBUG
if [ $? -ne 0 ]; then
    echo "Unable to start converged node"
    exit 1
fi
