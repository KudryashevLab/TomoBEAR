#!/bin/bash
SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
source $SCRIPTPATH/load_modules.sh
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/mpcdf/soft/CentOS_7/packages/x86_64/anaconda/3/2020.02/2020.02/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
eval "$__conda_setup"
else
if [ -f "/mpcdf/soft/CentOS_7/packages/x86_64/anaconda/3/2020.02/etc/profile.d/conda.sh" ]; then
. "/mpcdf/soft/CentOS_7/packages/x86_64/anaconda/3/2020.02/etc/profile.d/conda.sh"
else
export PATH="/mpcdf/soft/CentOS_7/packages/x86_64/anaconda/3/2020.02/2020.02/bin:$PATH"
fi
fi
unset __conda_setup
# <<< conda initialize <<<
eval $2
