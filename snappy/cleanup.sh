#!/bin/bash
VAL=1
if [ $# -ne 0 ]; then
    VAL=$1
fi
APP="mongo-snap-app-$VAL"
VOL="mongo-snap-vol-$VAL"

function cleanup()
{
    docker stop $APP      
    docker stop wait-$VOL 
    docker stop $VOL     
    docker rm -f $APP     
    docker rm -f wait-$VOL
    docker rm -f $VOL     
}

$(cleanup >/dev/null 2>&1)
