#!/bin/bash

<<<<<<< HEAD
CUDA_CACHE_MAXSIZE=$(echo "536870912*2" | bc)
export PATH="$(pwd)/dynamo/cuda/bin:$PATH"
=======
CUDA_CACHE_MAXSIZE = $(echo "536870912*2" | bc)
export PATH=$(pwd)/dynamo/cuda/bin:$PATH
>>>>>>> c3d94e5e6d31540350d66f7e38c1b834dee58a77

matlab
