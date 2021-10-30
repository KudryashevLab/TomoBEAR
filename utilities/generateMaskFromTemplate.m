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