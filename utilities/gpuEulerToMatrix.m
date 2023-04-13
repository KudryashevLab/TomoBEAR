%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This file is part of the TomoBEAR software.
% Copyright (c) 2021-2023 TomoBEAR Authors <https://github.com/KudryashevLab/TomoBEAR/blob/main/AUTHORS.md>
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU Affero General Public License as
% published by the Free Software Foundation, either version 3 of the
% License, or (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Affero General Public License for more details.
% 
% You should have received a copy of the GNU Affero General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function transformation_matrices = gpuEulerToMatrix(angles, varargin)

defaultMatrixOperation = "crotation";
defaultMatrixType = "homogeneous";
defaultDataType = "single";
defaultVolumeSize = 200;

p = inputParser;
addParameter(p, 'dataType', defaultDataType, @isstring);
addParameter(p, 'volumeSize', defaultVolumeSize, @isnumeric);
addParameter(p, 'matrixType', defaultMatrixType, @isstring);
addParameter(p, 'matrixOperation', defaultMatrixOperation, @isstring);

parse(p,varargin{:});
dataType = p.Results.dataType;
volumeSize = p.Results.volumeSize;
matrixType = p.Results.matrixType;
matrixOperation = p.Results.matrixOperation;

if matrixType == "homogeneous"
    transformation_matrix_template = zeros([4 4], dataType, 'gpuArray');
    transformation_matrix_template(end,end) = 1;
    if volumeSize ~= 0
        transformation_matrix_template(1:3,4) = (volumeSize / 2) + 1;
    else
        transformation_matrix_template(1:3,4) = 0;
    end
elseif matrixType == "normal"
    transformation_matrix_template = zeros([3 3], dataType, 'gpuArray');
end

transformation_matrices = repmat(transformation_matrix_template, [size(angles, 1), 1]);
for i = 1:size(angles, 1)
    tdrot = angles(i,1);
    tilt = angles(i,2);
    narot = angles(i,3);
    tdrot = deg2rad(tdrot);
    narot = deg2rad(narot);
    tilt = deg2rad(tilt);
    
    costdrot = cos(tdrot);
    cosnarot = cos(narot);
    costilt = cos(tilt);
    sintdrot = sin(tdrot);
    sinnarot = sin(narot);
    sintilt = sin(tilt);
    
    if matrixOperation == "interpolation"
        transformation_matrices(((i - 1) * 4) + 1, 1) = costdrot*cosnarot - sintdrot*costilt*sinnarot;
        transformation_matrices(((i - 1) * 4) + 1, 2) = - cosnarot*sintdrot - costdrot*costilt*sinnarot;
        transformation_matrices(((i - 1) * 4) + 1, 3) = sinnarot*sintilt;
        transformation_matrices(((i - 1) * 4) + 2, 1) = costdrot*sinnarot + cosnarot*sintdrot*costilt;
        transformation_matrices(((i - 1) * 4) + 2, 2) = costdrot*cosnarot*costilt - sintdrot*sinnarot;
        transformation_matrices(((i - 1) * 4) + 2, 3) = -cosnarot*sintilt;
        transformation_matrices(((i - 1) * 4) + 3, 1) = sintdrot*sintilt;
        transformation_matrices(((i - 1) * 4) + 3, 2) = costdrot*sintilt;
        transformation_matrices(((i - 1) * 4) + 3, 3) = costilt;
    elseif matrixOperation == "rotation"
        transformation_matrices(((i - 1) * 4) + 1, 1) = costdrot*cosnarot - sintdrot*costilt*sinnarot;
        transformation_matrices(((i - 1) * 4) + 1, 2) = - costdrot*sinnarot - cosnarot*sintdrot*costilt;
        transformation_matrices(((i - 1) * 4) + 1, 3) = sintdrot*sintilt;
        transformation_matrices(((i - 1) * 4) + 2, 1) = cosnarot*sintdrot + costdrot*costilt*sinnarot;
        transformation_matrices(((i - 1) * 4) + 2, 2) = costdrot*cosnarot*costilt - sintdrot*sinnarot;
        transformation_matrices(((i - 1) * 4) + 2, 3) = -costdrot*sintilt;
        transformation_matrices(((i - 1) * 4) + 3, 1) = sinnarot*sintilt;
        transformation_matrices(((i - 1) * 4) + 3, 2) = cosnarot*sintilt;
        transformation_matrices(((i - 1) * 4) + 3, 3) = costilt;
     elseif matrixOperation == "crotation"
        transformation_matrices(((i - 1) * 4) + 1, 1) = costdrot*cosnarot - costilt*sintdrot*sinnarot;
        transformation_matrices(((i - 1) * 4) + 1, 2) = sintdrot*cosnarot + costilt*costdrot*sinnarot;
        transformation_matrices(((i - 1) * 4) + 1, 3) = sintilt*sinnarot;
        transformation_matrices(((i - 1) * 4) + 2, 1) = -costdrot*sinnarot - costilt*sintdrot*cosnarot;
        transformation_matrices(((i - 1) * 4) + 2, 2) = -sintdrot*sinnarot + costilt*costdrot*cosnarot;
        transformation_matrices(((i - 1) * 4) + 2, 3) = sintilt*cosnarot;
        transformation_matrices(((i - 1) * 4) + 3, 1) = sintilt*sintdrot;
        transformation_matrices(((i - 1) * 4) + 3, 2) = -sintilt*costdrot;
        transformation_matrices(((i - 1) * 4) + 3, 3) = costilt;
    end
end
end

