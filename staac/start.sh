#!/bin/bash
###############################################################################
# Application: mongo
#
# Start mongodb container backed by Blockbridge persistent storage.
###############################################################################
VAL=1
if [ $# -ne 0 ]; then
    VAL=$1
fi
APP="mongo-app-$VAL"
VOL="mongo-vol-$VAL"

# start Blockbridge persistent storage volume
echo -n "Starting persistent storage container $VOL: "
docker start $VOL

# wait for storage to come online
echo "Waiting for $VOL to come online:"
docker run --volumes-from $VOL --name wait-$VOL --rm blockbridge/wait

# check if storage is online
if [ $? -ne 0 ]; then
    docker rm -f wait-$VOL
    echo "$VOL failed to come online"
    exit 1
fi
echo "$VOL is online"

# start mongo with persistent volumes from storage container
echo -n "Starting $APP: "
docker start $APP
echo "$APP is running."
