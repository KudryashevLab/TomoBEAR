%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This file is part of the TomoBEAR software.
% Copyright (c) 2021,2022,2023 TomoBEAR Authors <https://github.com/KudryashevLab/TomoBEAR/blob/main/AUTHORS.md>
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published
% by the Free Software Foundation, either version 3 of the License,
% or (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [rescaled_pixelsize, apix] = getApix(configuration, scaling_binning_factor)
if nargin == 1
    scaling_binning_factor = 1;
end

if isfield(configuration, "apix")
    rescaled_pixelsize = configuration.apix * configuration.ft_bin...
        * scaling_binning_factor;
    apix = configuration.apix;
elseif isfield(configuration, "greatest_apix")
    rescaled_pixelsize = configuration.greatest_apix...
        * configuration.ft_bin * scaling_binning_factor;
    apix = configuration.greatest_apix;
elseif isfield(configuration, "smallest_apix")
    rescaled_pixelsize = configuration.smallest_apix...
        * configuration.ft_bin * scaling_binning_factor;
    apix = configuration.smallest_apix;    
else
    error("ERROR: no pixel size entered or detected!");
end
end

