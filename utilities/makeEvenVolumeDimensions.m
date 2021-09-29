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

