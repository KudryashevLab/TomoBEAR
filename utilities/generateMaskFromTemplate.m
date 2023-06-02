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

function mask_binarized_smoothed_cleaned = generateMaskFromTemplate(configuration, template)
mask = dbandpass(-template, configuration.mask_bandpass);
mask_binarized = gather(imbinarize(mask));
mask_binarized_morphed = zeros(size(mask_binarized));
for i = 1:length(mask_binarized)
    mask_binarized_morphed(:,:,i) = bwmorph(mask_binarized(:,:,i),...
        "thicken", ceil(size(mask_binarized,3) * configuration.ratio_mask_pixels_based_on_unbinned_pixels));
end
for i = 1:length(mask_binarized)
    mask_binarized_morphed(:,i,:) = bwmorph(reshape(...
        mask_binarized_morphed(:,i,:), size(mask_binarized_morphed(:,:,i), [1 2])),...
        "thicken", ceil(size(mask_binarized,2) * configuration.ratio_mask_pixels_based_on_unbinned_pixels));
end
mask_binarized_smoothed_cleaned = dbandpass(mask_binarized_morphed, configuration.mask_bandpass);
end