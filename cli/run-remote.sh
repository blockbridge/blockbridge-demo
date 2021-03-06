#!/bin/bash
###############################################################################
# Run a Blockbridge CLI shell (remote management)
###############################################################################

###############################################################################
# configuration parameters. Set here or in environment.
###############################################################################

# management node API endpoint
: ${BLOCKBRIDGE_API_HOST=""}

###############################################################################
# check variables set
###############################################################################
${BLOCKBRIDGE_API_HOST:?"BLOCKBRIDGE_API_HOST is not set"}

###############################################################################
# run CLI shell container
###############################################################################
docker run --it --rm --env BLOCKBRIDGE_API_HOST="$BLOCKBRIDGE_API_HOST" blockbridge/cli
