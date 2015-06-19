#!/bin/bash
###############################################################################
# Run a Blockbridge simulator storage node with IP address configured for
# remote storage access.
###############################################################################

###############################################################################
# defines
###############################################################################
readonly BB_SN_INPUT_CHAIN="BLOCKBRIDGE_INPUT_SN"

###############################################################################
# configuration parameters. Set here or in environment.
###############################################################################

# management node simulator name
: ${BB_MN_SIM_NAME="bbsim-mn"}

# management node management port
: ${BB_MN_SSL_PORT=443}

# management node IP address
: ${BB_MN_SIM_IP=""}

# management node api key (pulls from local container if unspecified)
: ${BB_MN_API_KEY=""}

# storage node simulator name (defaults below if unspecified)
: ${BB_SN_SIM_NAME=""}

# storage node IP address
: ${BB_SN_SIM_IP=""}

# run simulator in debug mode
#BB_DEBUG="--debug"

###############################################################################
# config check
###############################################################################
: ${BB_MN_SIM_NAME:?"BB_MN_SIM_NAME (management node simulator name) is not set"}
: ${BB_MN_SSL_PORT:?"BB_MN_SSL_PORT (management node management port) is not set"}
: ${BB_MN_SIM_IP:?"BB_MN_SIM_IP (management node IP address) is not set"}
: ${BB_SN_SIM_IP:?"BB_SN_SIM_IP (storage node IP address) is not set"}

###############################################################################
# lookup API key from management node
###############################################################################
if [ -z "$BB_MN_API_KEY" ]; then
    echo "BB_MN_API_KEY (management node api key) is not set; attempting lookup with local management node"
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
        echo "Failed to find API key from management node"
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


    sudo iptables -N $BB_SN_INPUT_CHAIN >/dev/null 2>&1
    set -e
    sudo iptables -A $BB_SN_INPUT_CHAIN -p tcp                             \
                                        --dst $BB_SN_SIM_IP                \
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
# run storage node
###############################################################################
PARAMS=(--name "$BB_SN_SIM_NAME"                                    \
        --env BB_SIM_MODE="storage"                                 \
        --env BLOCKBRIDGE_API_KEY="$BB_MN_API_KEY"                  \
        --env BLOCKBRIDGE_API_HOST="$BB_MN_SIM_IP:$BB_MN_SSL_PORT"  \
        --env BB_SIM_IP="$BB_SN_SIM_IP"                             \
        --publish $BB_SN_SIM_IP:3260:3260                           \
        --privileged                                                \
        --ulimit msgqueue=-1                                        \
        --ulimit memlock=-1                                         \
        --detach)

echo -n "Starting storage node: "
docker run "${PARAMS[@]}" blockbridge/simulator $BB_DEBUG
if [ $? -ne 0 ]; then
    echo "Unable to start storage node"
    exit 1
fi
