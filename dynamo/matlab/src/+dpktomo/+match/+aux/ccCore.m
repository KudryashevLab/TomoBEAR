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
rotatedMaskPadded_ft = fftn(rotatedMaskPadded);
chunkNormalized_sq_ft = fftn(chunkNormalized.^2);
chunkNormalized_ft = fftn(chunkNormalized);
%P11 = arrayfun(@(x,y)(x.*y),rotatedMaskPadded_ft,conj(chunkNormalized_sq_ft));
P1 = rotatedMaskPadded_ft .* conj(chunkNormalized_sq_ft);
clear chunkNormalized_sq_ft;
%P12 = arrayfun(@(x,y)(x.*y),rotatedMaskPadded_ft,conj(chunkNormalized_ft));
P2 = rotatedMaskPadded_ft .* conj(chunkNormalized_ft);
clear rotatedMaskPadded_ft;
mcn_final = sqrt(ifftn(P1) - 1 * (ifftn(P2).^2) / (Nmask^1)) * norm_rotatedTemplate;
clear P1;
clear P2;
%mcn_final = sqrt(ifftn(fftn(rotatedMaskPadded) .* conj(fftn(chunkNormalized.^2))) - 1 * (ifftn(fftn(rotatedMaskPadded) .* conj(fftn(chunkNormalized))).^2) / (Nmask^1)) * norm_rotatedTemplate;
%mcn_final = real(sqrt(complex(ifftn(fftn(rotatedMaskPadded) .* conj(fftn(chunkNormalized.^2)))) - 1 * (real(ifftn(fftn(rotatedMaskPadded) .* conj(fftn(chunkNormalized)))).^2) / (Nmask^1))) * norm_rotatedTemplate;
% clear norm_data_moving_mask;
%clear norm_rotatedTemplate ;


% to compute intensities calculated on domains that move solidarily with the template

% rotatedTemplatePadded = fftn(rotatedTemplatePadded);
% clear rotatedTemplatePadded;
% RD = real(ifftn(fftn(rotatedTemplatePadded) .* conjD2)); % RD in CUDA version (for Rotated particle <-> Data)
% clear P1;
% identify the elements that would produce singularities in the numerator
% indproblem=find(mcn_final==0);
rotatedTemplatePadded_ft = fftn(rotatedTemplatePadded);
P3 = rotatedTemplatePadded_ft.*conj(chunkNormalized_ft);
P3_ift = ifftn(P3);
clear P3;
mc = P3_ift./mcn_final;
clear P3_ift;
mc = real(mc);
% clear RD;
mc(mcn_final == 0) = -1;

