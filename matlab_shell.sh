#!/bin/bash
#unset KMP_STACKSIZE
# NOTE: it is at the moment best not to clutter the output since some
# statements rely on the fact that the output is only from the executed command
#if [ "$HOSTNAME" != "xps9570linux" ] || [ "$HOSTNAME" != "X080-ubuntu" ]; then
#    SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
#    source $SCRIPTPATH/load_modules.sh
#else
#    # NOTE: LD_LIBRARY_PATH from this shell let imod work from native not need to check
#    #echo $LD_LIBRARY_PATH
#    #export LD_LIBRARY_PATH=/home/nibalysc/Programs/anaconda3/lib
#    #export LD_LIBRARY_PATH=/home/nibalysc/Projects/phd/extern/dip/Linuxa64/lib/
#    # added by Anaconda3 2018.12 installer
#    # >>> conda init >>>
#    # !! Contents within this block are managed by 'conda init' !!
#    __conda_setup="$(CONDA_REPORT_ERRORS=false '/home/nibalysc/Programs/miniconda3/bin/conda' shell.bash hook 2> /dev/null)"
#    if [ $? -eq 0 ]; then
#        \eval "$__conda_setup"
#    else
#        if [ -f "/home/nibalysc/Programs/miniconda3/etc/profile.d/conda.sh" ]; then
#    # . "/home/nibalysc/Programs/miniconda3/etc/profile.d/conda.sh"  # commented out by conda initialize
#            CONDA_CHANGEPS1=false conda activate base
#        else
#            \export PATH="/home/nibalysc/Programs/anaconda3/bin:$PATH"
#        fi
#    fi
#    unset __conda_setup
#    # <<< conda init <<<#
#
#    # >>> conda initialize >>>
#    # !! Contents within this block are managed by 'conda init' !!
#    __conda_setup="$('/home/nibalysc/Programs/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
#    if [ $? -eq 0 ]; then
#        eval "$__conda_setup"
#    else
#        if [ -f "/home/nibalysc/Programs/miniconda3/etc/profile.d/conda.sh" ]; then
#            . "/home/nibalysc/Programs/miniconda3/etc/profile.d/conda.sh"
#        else
#            export PATH="/home/nibalysc/Programs/miniconda3/bin:$PATH"
#        fi
#    fi
#    unset __conda_setup
#    # <<< conda initialize <<<
#
#    conda activate eman2
#    export LD_LIBRARY_PATH=/usr/local/cuda-10.1/targets/x86_64-linux/lib:$LD_LIBRARY_PATH
#fi
#
## NOTE: Don't use the next command from the link below to execute shell
## commands, makes trouble in interpreting passed shell command
## https://de.mathworks.com/help/matlab/matlab_external/changing-environment-variables-for-shell-escape-functions.html
##exec ${SHELL:-/bin/bash} $*
#
SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
source $SCRIPTPATH/load_modules.sh
eval $2
