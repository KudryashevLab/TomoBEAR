#! /bin/bash

sbr="$(qsub "$@")"

if [[ "$sbr" =~ Submitted\ batch\ job\ ([0-9]+) ]]; then
    echo "${BASH_REMATCH[1]}"
    exit 0
else
    echo "qsub failed!"
    exit 1
fi