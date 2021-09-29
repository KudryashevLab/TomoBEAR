% resize_template
%
% used in order to change the size of a volume with matlab spline interpolation

% note
% temporarily we use a copy of the local resize_template

 
 
% Author: Daniel Castano-Diez, April 2012 (daniel.castano@unibas.ch)
% Copyright (c) 2012 Daniel Castano-Diez and Henning Stahlberg
% Center for Cellular Imaging and Nano Analytics 
% Biocenter, University of Basel
% 
% This software is issued under a joint BSD/GNU license. You may use the
% source code in this file under either license. However, note that the
% complete Dynamo software packages have some GPL dependencies,
% so you are responsible for compliance with the licenses of these packages
% if you opt to use BSD licensing. The warranty disclaimer below holds
% in either instance.
% 
% This complete copyright notice must be included in any revised version of the
% source code. Additional authorship citations may be added, but existing
% author citations must be preserved.
% 
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  2111-1307 USA
 
 
function volume_small=dynamo_resize_template(template_big,size_new_template);
[s1,s2,s3]=size(template_big);

% passes it to a binnig operation if possible
size_new_template_scalar=size_new_template(1);
if mod(s1,size_new_template_scalar)==0
    binning_factor=log2(s1/size_new_template_scalar);  
    % check accuracy of redres function
    volume_small=dynamo_bin(template_big,binning_factor);
    return;
end    
%    
    
pixel_size_1=1;
pixel_size_2=s1/size_new_template;
volume_small=rescale_pixel_size_local(template_big, pixel_size_1,pixel_size_2,size_new_template);

function vol_new_out=rescale_pixel_size_local(template, pixel_size_1,pixel_size_2,size_2);



Interval = pixel_size_2/pixel_size_1;
[s1,s2,s3]=size(template);
[x,y,z] = meshgrid(1:s1,1:s2,1:s3);
[xi,yi,zi] = meshgrid(1:Interval:s1,1:Interval:s2,1:Interval:s3);
vol_new = interp3(x,y,z,template,xi,yi,zi,'spline');

[s1,s2,s3]=size(vol_new);
vol_new_out=zeros([size_2 size_2 size_2]);
vol_new_out(1:s1,1:s2,1:s3)=vol_new;
 
