#!/bin/bash
###############################################################################
# Cleanup Blockbridge simulator
###############################################################################

###############################################################################
# defines
###############################################################################
readonly BB_MN_INPUT_CHAIN="BLOCKBRIDGE_INPUT_MN"

###############################################################################
# firewall cleanup
###############################################################################
function remove_firewall()
{
    command -v iptables >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Not modifying firewall rules; iptables command not found in path; remote connections may not work as expected"
        return
    fi

    echo "Removing simulator firewall rules (may need sudo password)"

    while [ $? -eq 0 ]; do
        sudo iptables -D INPUT -j $BB_MN_INPUT_CHAIN >/dev/null 2>&1
    done

    sudo iptables -F $BB_MN_INPUT_CHAIN >/dev/null 2>&1
    sudo iptables -X $BB_MN_INPUT_CHAIN >/dev/null 2>&1
}

# remove firewall rules
remove_firewall

###############################################################################
# stop and remove simulator containers and volumes
###############################################################################
echo "Stopping management node: $(docker stop bbsim-mn)"
echo "Removing management node: $(docker rm -fv bbsim-mn)"
