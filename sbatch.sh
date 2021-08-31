#! /bin/bash

sbr="$(sbatch "$@")"

if [[ "$sbr" =~ Submitted\ batch\ job\ ([0-9]+) ]]; then
    echo "${BASH_REMATCH[1]}"
    exit 0
else
    echo "sbatch failed"
    exit 1
fi