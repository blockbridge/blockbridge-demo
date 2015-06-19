#!/bin/bash
###############################################################################
# Run iscsid container.
###############################################################################
docker run --name iscsid                            \
           --privileged                             \
           --detach                                 \
           --restart always                         \
           --volume /lib/modules:/lib/modules       \
           --volume /proc/1/ns:/ns-net              \
           blockbridge/iscsid
