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


function result = versionGreaterThan(version, version_to_be_compared_to, delimiter)
if nargin == 2
    delimiter = ".";
end
version_numbers_str = strsplit(version, delimiter);
version_numbers_to_be_compared_to_str = strsplit(version_to_be_compared_to, delimiter);
for i = 1:length(version_numbers_str)
    version_numbers(i) = str2double(version_numbers_str(i));
	version_numbers_to_be_compared_to(i) = str2double(version_numbers_to_be_compared_to_str(i));
end
if version_numbers(1) >= version_numbers_to_be_compared_to(1)
    result = true;
    if version_numbers(2) >= version_numbers_to_be_compared_to(2)
        result = true;
        if version_numbers(3) >= version_numbers_to_be_compared_to(3)
            result = true;
        else
            result = false;
        end
    else
        result = false;
    end
else
    result = false;
end
end

