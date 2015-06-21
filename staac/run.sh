#!/bin/bash
###############################################################################
# Application: mongo
#
# Start a mongodb application backed by Blockbridge persistent storage.
###############################################################################
VAL=1
if [ $# -ne 0 ]; then
    VAL=$1
fi
APP="mongo-app-$VAL"
VOL="mongo-vol-$VAL"
ENV="$(dirname $0)/env.sh"

# run persistent autovol storage for '/data/db'
echo -n "Running persistent storage container $VOL: "
docker run --name $VOL                                              \
           --env-file $ENV                                          \
           --env LABEL="mongodb-demo-$VAL"                          \
           --privileged                                             \
           --detach                                                 \
           --volumes-from iscsid                                    \
           --volume /proc/$(pgrep -f /usr/bin/docker)/ns:/ns-mnt    \
           --volume /proc/1/ns:/ns-net                              \
           --volume /data/db                                        \
           blockbridge/autovol

# wait for storage to come online
echo "Waiting for $VOL to come online:"
docker run --volumes-from $VOL --name wait-$VOL --rm blockbridge/wait

# check if storage is online
if [ $? -ne 0 ]; then
    docker rm -f wait-$VOL
    echo "$VOL failed to come online"
    exit 1
fi

# volume is online
echo "$VOL is online."

# run mongo with persistent volumes from storage container
echo -n "Running $APP: "
docker run --name $APP --volumes-from $VOL --detach mongo

# mongo is running
echo "$APP is running."
