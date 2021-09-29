%
% SEE ALSO
% dpktomo.match.aux.flipCC   : to get the actual positioning
function mc = ccCore(rotatedTemplatePadded, rotatedMaskPadded, chunkNormalized, Nmask, norm_rotatedTemplate)

% to compute averages calculated on domains that move solidarily with the template
% rotatedMaskPadded = fftn(rotatedMaskPadded);
% clear rotatedMaskPadded;
%mca = real(ifftn(rotatedMaskPadded .* conjD2));  % DMDM in the cuda version
% clear conjD2;
% mca2 = ;
%clear mca;
%mcn = ; % D2M in the CUDA version (data square against mask)
% clear conjD22;
% clear PM;
%mcn_joint = ;
% clear mca2;
%clear Nmask;
%norm_data_moving_mask = sqrt(mcn_joint);
%clear mcn_joint;
% mcn_final = sqrt(real(ifftn(fftn(rotatedMaskPadded) .* conj(fftn(chunkNormalized.^2)))) - 1 * (real(ifftn(fftn(rotatedMaskPadded) .* conj(fftn(chunkNormalized))))^2) / (Nmask^1)) * norm_rotatedTemplate;
mcn_final = sqrt(real(ifftn(fftn(rotatedMaskPadded) .* conj(fftn(chunkNormalized.^2)))) - 1 * (real(ifftn(fftn(rotatedMaskPadded) .* conj(fftn(chunkNormalized)))).^2) / (Nmask^1)) * norm_rotatedTemplate;
% clear norm_data_moving_mask;
%clear norm_rotatedTemplate ;


% to compute intensities calculated on domains that move solidarily with the template

% rotatedTemplatePadded = fftn(rotatedTemplatePadded);
% clear rotatedTemplatePadded;
% RD = real(ifftn(fftn(rotatedTemplatePadded) .* conjD2)); % RD in CUDA version (for Rotated particle <-> Data)
% clear P1;
% identify the elements that would produce singularities in the numerator
% indproblem=find(mcn_final==0);
mc = real(ifftn(fftn(rotatedTemplatePadded).*conj(fftn(chunkNormalized))))./mcn_final;
% clear RD;
mc(mcn_final == 0) = -1;

