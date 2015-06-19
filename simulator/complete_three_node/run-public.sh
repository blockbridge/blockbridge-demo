#!/bin/bash
###############################################################################
# Run a Blockbridge simulator management node and 3 storage nodes with IP
# addresses configured for remote storage access.
###############################################################################

###############################################################################
# defines
###############################################################################
readonly BB_MN_INPUT_CHAIN="BLOCKBRIDGE_INPUT_MN"
readonly BB_SN_INPUT_CHAIN="BLOCKBRIDGE_INPUT_SN"
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

# storage node simulator names
: ${BB_SN1_SIM_NAME="bbsim-sn1"}
: ${BB_SN2_SIM_NAME="bbsim-sn2"}
: ${BB_SN3_SIM_NAME="bbsim-sn3"}

# storage node IP addresses
: ${BB_SN1_SIM_IP=""}
: ${BB_SN2_SIM_IP=""}
: ${BB_SN3_SIM_IP=""}

# run simulator in debug mode
#BB_DEBUG="--debug"

###############################################################################
# check parameters
###############################################################################
: ${BB_MN_SIM_NAME:?"BB_MN_SIM_NAME (management node simulator name) is not set"}
: ${BB_MN_SSL_PORT:?"BB_MN_SSL_PORT (management node management port) is not set"}
: ${BB_MN_WEB_PORT:?"BB_MN_WEB_PORT (management node web redirect) is not set"}
: ${BB_MN_SIM_IP:?"BB_MN_SIM_IP (management node IP address) is not set"}
: ${BB_SN1_SIM_NAME:?"BB_SN1_SIM_NAME (storage node 1 simulator name) is not set"}
: ${BB_SN2_SIM_NAME:?"BB_SN2_SIM_NAME (storage node 2 simulator name) is not set"}
: ${BB_SN3_SIM_NAME:?"BB_SN3_SIM_NAME (storage node 3 simulator name) is not set"}
: ${BB_SN1_SIM_IP:?"BB_SN1_SIM_IP (storage node 1 IP address) is not set"}
: ${BB_SN2_SIM_IP:?"BB_SN2_SIM_IP (storage node 2 IP address) is not set"}
: ${BB_SN3_SIM_IP:?"BB_SN3_SIM_IP (storage node 3 IP address) is not set"}

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

    # storage rules
    sudo iptables -N $BB_SN_INPUT_CHAIN >/dev/null 2>&1
    set -e
    sudo iptables -A $BB_SN_INPUT_CHAIN -p tcp                             \
                                        --dst $BB_SN1_SIM_IP               \
                                        --dport 3260                       \
                                        -j ACCEPT                          \
                                        -m comment                         \
                                        --comment "iscsi storage"
    sudo iptables -A $BB_SN_INPUT_CHAIN -p tcp                             \
                                        --dst $BB_SN2_SIM_IP               \
                                        --dport 3260                       \
                                        -j ACCEPT                          \
                                        -m comment                         \
                                        --comment "iscsi storage"
    sudo iptables -A $BB_SN_INPUT_CHAIN -p tcp                             \
                                        --dst $BB_SN3_SIM_IP               \
                                        --dport 3260                       \
                                        -j ACCEPT                          \
                                        -m comment                         \
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
# run management node
###############################################################################
PARAMS=(--name "$BB_MN_SIM_NAME"                            \
        --env BB_SIM_MODE="management"                      \
        --env BB_SIM_IP="$BB_MN_SIM_IP"                     \
        --publish $BB_MN_SIM_IP:$BB_MN_SSL_PORT:443         \
        --publish $BB_MN_SIM_IP:$BB_MN_WEB_PORT:80          \
        --publish $BB_MN_SIM_IP:$BB_MP_PORT:$BB_MP_PORT     \
        --publish $BB_MN_SIM_IP:$BB_MLP_PORT:$BB_MLP_PORT   \
        --privileged                                        \
        --ulimit msgqueue=-1                                \
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
# run storage nodes
###############################################################################
# storage node 1
PARAMS=(--name "$BB_SN1_SIM_NAME"                                   \
        --env BB_SIM_MODE="storage"                                 \
        --env BLOCKBRIDGE_API_KEY="$BB_MN_API_KEY"                  \
        --env BLOCKBRIDGE_API_HOST="$BB_MN_SIM_IP:$BB_MN_SSL_PORT"  \
        --env BB_SIM_IP="$BB_SN1_SIM_IP"                            \
        --publish $BB_SN1_SIM_IP:3260:3260                          \
        --privileged                                                \
        --ulimit msgqueue=-1                                        \
        --ulimit memlock=-1                                         \
        --detach)

echo -n "Starting storage node 1: "
docker run "${PARAMS[@]}" blockbridge/simulator $BB_DEBUG
if [ $? -ne 0 ]; then
    echo "Unable to start storage node 1"
    exit 1
fi

# storage node 2
PARAMS=(--name "$BB_SN2_SIM_NAME"                                   \
        --env BB_SIM_MODE="storage"                                 \
        --env BLOCKBRIDGE_API_KEY="$BB_MN_API_KEY"                  \
        --env BLOCKBRIDGE_API_HOST="$BB_MN_SIM_IP:$BB_MN_SSL_PORT"  \
        --env BB_SIM_IP="$BB_SN2_SIM_IP"                            \
        --publish $BB_SN2_SIM_IP:3260:3260                          \
        --privileged                                                \
        --ulimit msgqueue=-1                                        \
        --ulimit memlock=-1                                         \
        --detach)

echo -n "Starting storage node 2: "
docker run "${PARAMS[@]}" blockbridge/simulator $BB_DEBUG
if [ $? -ne 0 ]; then
    echo "Unable to start storage node 2"
    exit 1
fi

# storage node 3
PARAMS=(--name "$BB_SN3_SIM_NAME"                                   \
        --env BB_SIM_MODE="storage"                                 \
        --env BLOCKBRIDGE_API_KEY="$BB_MN_API_KEY"                  \
        --env BLOCKBRIDGE_API_HOST="$BB_MN_SIM_IP:$BB_MN_SSL_PORT"  \
        --env BB_SIM_IP="$BB_SN3_SIM_IP"                            \
        --publish $BB_SN3_SIM_IP:3260:3260                          \
        --privileged                                                \
        --ulimit msgqueue=-1                                        \
        --ulimit memlock=-1                                         \
        --detach)

echo -n "Starting storage node 3: "
docker run "${PARAMS[@]}" blockbridge/simulator $BB_DEBUG
if [ $? -ne 0 ]; then
    echo "Unable to start storage node 3"
    exit 1
fi
