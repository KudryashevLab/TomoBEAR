function vol = gpuEllipsoid(radii,siz,position,smoothing_pixels)
if ndims(siz) > 2
    siz = size(siz);
else
    if numel(radii) == 1
        radii = radii * [1, 1, 1];
    end
    if numel(siz) == 1
        siz = gpuArray(single(siz * [1, 1, 1]));
        s1 = siz(1);
        s2 = siz(2);
        s3 = siz(3);
    else
        s1 = gpuArray(single(siz(1)));
        s2 = gpuArray(single(siz(2)));
        s3 = gpuArray(single(siz(3)));
    end
end

set_default_or_empty('position', (siz(1)/2+1) * [1 1 1]);

if numel(position) == 1
    position = position * [1 1 1];
end

if prod(radii) == 0
    vol = zeros(siz);
    return;
end

[r{1}, r{2}, r{3}] = ndgrid(1:s1, 1:s2, 1:s3);
c = cell(3, 1);
for i=1:3
    c{i} = (r{i} - position(i)) .^ 2 / (radii(i)) ^ 2;
end

vol = single(sqrt(sum(cat(4,c{:}),4)) <= 1);

% now create a smoothing effect
if exist('smoothing_pixels', 'var')
    sigma = smoothing_pixels / radii(1); % should be corrected for ellipsoid
    ind_outside = single(find(vol > 1));
    distance_plateau = sqrt(c{1}(ind_outside)+c{2}(ind_outside)+c{3}(ind_outside));
    distance_plateau_weighted = (distance_plateau-1) ./ (sigma);
    vol(ind_outside)= exp(-(distance_plateau_weighted) .^ 2);
    vol(vol < 0.13) = 0;
end
end