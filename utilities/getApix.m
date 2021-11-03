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

