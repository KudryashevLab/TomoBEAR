% NOTE: https://stackoverflow.com/questions/26763974/histogram-matching-of-two-images-without-using-histeq
function output_image = histogramEqualization(image_1, image_2)
bin_counts = 2^16;
M = zeros(bin_counts,1,'uint16'); %// Store mapping - Cast to uint8 to respect data type
hist1 = imhist(image_1, bin_counts); %// Compute histograms
hist2 = imhist(image_2, bin_counts);
cdf1 = cumsum(hist1) / numel(image_1); %// Compute CDFs
cdf2 = cumsum(hist2) / numel(image_2);

%// Compute the mapping
for idx = 1 : bin_counts
    [~,ind] = min(abs(cdf1(idx) - cdf2));
    M(idx) = ind-1;
end

%// Now apply the mapping to get first image to make
%// the image look like the distribution of the second image
output_image = M(uint16(image_1 + 1));
end
