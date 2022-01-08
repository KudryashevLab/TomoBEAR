#!/bin/bash

CUDA_CACHE_MAXSIZE=$(echo "536870912*2" | bc)
export PATH="$(pwd)/dynamo/cuda/bin:$PATH"
matlab $@
