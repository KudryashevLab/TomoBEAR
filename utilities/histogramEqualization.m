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


% NOTE: https://stackoverflow.com/questions/26763974/histogram-matching-of-two-images-without-using-histeq
function output_image = histogramEqualization(image_1, image_2)
bin_counts = 2^16;
M = zeros(bin_counts,1,'uint16'); % Store mapping - Cast to uint8 to respect data type
hist1 = imhist(image_1, bin_counts); % Compute histograms
hist2 = imhist(image_2, bin_counts);
cdf1 = cumsum(hist1) / numel(image_1); % Compute CDFs
cdf2 = cumsum(hist2) / numel(image_2);

% Compute the mapping
for idx = 1 : bin_counts
    [~,ind] = min(abs(cdf1(idx) - cdf2));
    M(idx) = ind-1;
end

% Now apply the mapping to get first image to make
% the image look like the distribution of the second image
output_image = M(uint16(image_1 + 1));
end
