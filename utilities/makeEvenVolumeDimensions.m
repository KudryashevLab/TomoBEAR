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


function volume_out = makeEvenVolumeDimensions(volume_in, mean_value)
if mod(length(volume_in), 2) == 1
    % TODO: adjust for non cubic sizes
    volume_out = zeros(size(volume_in) + 1);
    if nargin == 1
        for i = length(volume_in)
            slice = volume_in(:,:,i);
            mean_value = mean(slice(:));
            volume_out(:,:,i) = mean_value;
        end
        volume_out(:,:,i + 1) = mean_value;
    else
        volume_out(:,:,:) = mean_value;
    end
        
    volume_out(1:size(volume_in,1),1:size(volume_in,2),1:size(volume_in,3)) = volume_in;
else
    volume_out = volume_in;
end
end

