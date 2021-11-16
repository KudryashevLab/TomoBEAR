In the following directions, replace MR/v98 by the directory on the target machine where MATLAB is installed, or MR by the directory where the MATLAB Runtime is installed.

(1) Set the environment variable XAPPLRESDIR to this value:

MR/v98/X11/app-defaults


(2) If the environment variable LD_LIBRARY_PATH is undefined, set it to the following:

MR/v98/runtime/glnxa64:MR/v98/bin/glnxa64:MR/v98/sys/os/glnxa64:MR/v98/sys/opengl/lib/glnxa64

If it is defined, set it to the following:

${LD_LIBRARY_PATH}:MR/v98/runtime/glnxa64:MR/v98/bin/glnxa64:MR/v98/sys/os/glnxa64:MR/v98/sys/opengl/lib/glnxa64