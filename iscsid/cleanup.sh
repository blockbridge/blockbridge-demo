#!/bin/bash
###############################################################################
# Cleanup iscsid container.
###############################################################################
docker stop iscsid
docker rm -f iscsid
