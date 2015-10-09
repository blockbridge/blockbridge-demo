#!/bin/bash
###############################################################################
# Run iscsid container.
###############################################################################
docker run --name iscsid                            \
           --privileged                             \
           --detach                                 \
           --restart always                         \
           --volume /etc/iscsi:/etc/iscsi           \
           --volume /lib/modules:/lib/modules       \
           --volume /proc/1/ns:/ns-net              \
           blockbridge/iscsid
