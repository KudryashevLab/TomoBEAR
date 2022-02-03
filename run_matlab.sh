#!/bin/bash

CUDA_CACHE_MAXSIZE=$(echo "536870912*2" | bc)
export PATH="$(pwd)/dynamo/cuda/bin:$PATH"
export PATH_COPY=$PATH
export LD_LIBRARY_PATH_COPY=$LD_LIBRARY_PATH
matlab $@
