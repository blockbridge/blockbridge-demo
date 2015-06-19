#!/bin/bash
VAL=1
if [ $# -ne 0 ]; then
    VAL=$1
fi
APP="mongo-app-$VAL"
VOL="mongo-vol-$VAL"

echo -n "Stopping $APP: "
docker stop $APP

echo -n "Stopping $VOL: "
docker stop $VOL