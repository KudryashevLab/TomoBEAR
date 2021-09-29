#!/bin/bash
#https://stackoverflow.com/questions/4774054/reliable-way-for-a-bash-script-to-get-the-full-path-to-itself
SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

export PATH=$SCRIPTPATH/dynamo/cuda/bin:$PATH

source $SCRIPTPATH/load_modules.sh

$SCRIPTPATH/tomoBEAR/for_redistribution_files_only/run_tomoBEAR.sh \
    $MCR_ROOT $1 $2 $3 $4 $5 $6 $7
