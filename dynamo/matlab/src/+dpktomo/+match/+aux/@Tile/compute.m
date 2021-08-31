% compute
%
%  INPUT
%
%  FLAGS
%
%  OUTPUT
%
%  SYNTAX
%
function compute(obj,varargin)
o = mbs.o;
timeStart = clock();
o.e(' Computing tile %d',obj.tag);
o.e('   -Range (original block): %s',obj.prettyRange());
o.e('   -Range (binned block)  : %s',obj.binnedTile.prettyRange());

operationalData = obj.process.operationalData;

chunk       = obj.getSourceBlock(); % includes binning

% binnig has been taken into account in the preoperative setup
template    = operationalData.template;
mask        = operationalData.mask;
gpuTemplate = gpuArray(single(template));
gpuMask = gpuArray(single(mask));


fMaskCorner = fftshift(operationalData.fmask);

triplets     = operationalData.triplets;

[Nx,Ny,Nz] = size(chunk);
[tx,ty,tz] = size(template);
sizeTemplate = [tx,ty,tz];
sizeData     = [Nx,Ny,Nz];



normTemplate = operationalData.normTemplate;
Nmask        = operationalData.NMask;

%
chunkNormalized = dynamo_normalize_roi(chunk);

%conjP        = gpuArray(conj(fftn(chunkNormalized)));
%conjPSquared = gpuArray(conj(fftn(chunkNormalized.^2)));
%clear chunkNormalized;

% trackers
maxCC    = -1*ones(Nx,Ny,Nz,'single', "gpuArray");
tdrotMatrix  = 0*ones(Nx,Ny,Nz,'int16', "gpuArray");
tiltMatrix   = 0*ones(Nx,Ny,Nz,'int16', "gpuArray");
narotMatrix  = 0*ones(Nx,Ny,Nz,'int16', "gpuArray");

if any([tx,ty,tz]>[Nx,Ny,Nz])
    disp('Template is bigger than chunk!');
    return
end


NAngles = size(triplets,1);
setupTimeLapse   = etime(clock(), timeStart);


j = 1;
coordinates = single(-length(gpuTemplate)/2:1:(length(gpuTemplate)/2)-1);
[y_coordinates,...
    x_coordinates,...
    z_coordinates] = meshgrid(coordinates);
gpu_x_coordinates = gpuArray(x_coordinates(:));
gpu_y_coordinates = gpuArray(y_coordinates(:));
gpu_z_coordinates = gpuArray(z_coordinates(:));
gpu_h_coordinates =...
    ones(length(x_coordinates(:)), 1, "single", "gpuArray");

gpu_xyzh_coordinates = [gpu_x_coordinates, gpu_y_coordinates,...
    gpu_z_coordinates, gpu_h_coordinates];

siz = size(gpuTemplate, 1);
ellipsoid = gpuEllipsoid(siz/2, siz, siz/2+1, 0);
current_directory = pwd;
iteration_time_sum = 0;
iteration_file_id = fopen(string(pwd) + string(string(filesep)) + "ITERATION", "w+");
time_file_id = fopen(string(pwd) + string(string(filesep)) + "TIME_LEFT", "w+");

for i=1:NAngles
    iteration_begin = tic;
    if mod(i-1, 10) == 0
        fseek(iteration_file_id, 0, "bof");
        fprintf(iteration_file_id, "%d/%d", i + (NAngles * (obj.tag - 1)), NAngles * length(obj.partition.tiles));
    end
    rotatedTemplateCanvas = zeros(Nx,Ny,Nz,class(chunk), "gpuArray");
    rotatedMaskCanvas     = zeros(Nx,Ny,Nz,class(chunk), "gpuArray");
    myTriplet = triplets(i,:);
    
    
    gpu_transformation_matrix = gpuEulerToMatrix(myTriplet, "matrixOperation", "interpolation", "volumeSize", size(template, 1));
    %TODO: extract single precision function as datatype parameter
    
    
    gpu_rotated_coordinates =...
        gpu_xyzh_coordinates * gpu_transformation_matrix';
    
    rotatedTemplate =...
        reshape(interp3(gpuTemplate, gpu_rotated_coordinates(:,2),...
        gpu_rotated_coordinates(:,1),...
        gpu_rotated_coordinates(:,3), 'linear', 0), size(gpuTemplate));
    
    rotatedMask =...
        reshape(interp3(gpuMask, gpu_rotated_coordinates(:,2),...
        gpu_rotated_coordinates(:,1),...
        gpu_rotated_coordinates(:,3), 'linear', 0), size(gpuTemplate));
    
    
    
    rotatedTemplate = rotatedTemplate .* ellipsoid;
    rotatedMask = rotatedMask .* ellipsoid;
    
    
    %     rotatedTemplate = dynamo_rot(template,myTriplet);
    %     rotatedMask     = dynamo_rot(mask,myTriplet);
    %
    %     rotatedTemplate = dynamo_nan(rotatedTemplate);
    %     rotatedMask = dynamo_nan(rotatedMask);
    
    % recompute mask
    rotatedMask = dynamo_binarize(rotatedMask,0.5);
    indMask     = find(rotatedMask);
    Nmask       = length(find(indMask));
    
    if Nmask == 0
        disp('-------------------------------------------------');
        disp('Mask does not contain any non-zero points!!');
        disp('Switching off local masking....');
        rotatedMask(:,:,:)=1;
        indMask     = find(rotatedMask);
        Nmask       = length(find(indMask));
        
    end
    
    
    if obj.process.settings.applyFmask.value
        rotatedTemplate = fftn(rotatedTemplate);
        rotatedTemplate = real(ifftn(rotatedTemplate.*fMaskCorner));
    end
    
    % recompute norm of template
    
    if std(rotatedTemplate(find(rotatedMask)))<eps
        disp('-------------------------------------------------');
        disp('Mask does not see any intensity variance');
        disp('Switching off local masking....');
        rotatedMask(:,:,:)=1;
        indMask     = find(rotatedMask);
        Nmask       = length(find(indMask));
    end
    
    rotatedTemplate = dynamo_normalize_roi(rotatedTemplate,rotatedMask);
    normTemplate    = sqrt(sum(sum(sum(rotatedTemplate(indMask).^2))));
    if isnan(normTemplate)
        error('Template norm is NaN!!!');
    end
    
    
    rotatedTemplate = rotatedTemplate.*rotatedMask;
    
    rotatedTemplateCanvas(1:tx,1:ty,1:tz) = rotatedTemplate;
    rotatedMaskCanvas(1:tx,1:ty,1:tz)     = rotatedMask;
    
%    gpu_ccForBlock{j} = dpktomo.match.aux.ccCore(rotatedTemplateCanvas, rotatedMaskCanvas,...
%        conjP,conjPSquared,Nmask,normTemplate);
    gpu_ccForBlock = dpktomo.match.aux.ccCore(rotatedTemplateCanvas, rotatedMaskCanvas,...
            chunkNormalized, Nmask, normTemplate);
    
%    if max(gpu_ccForBlock{j}(:)) >1
%        disp('<attention, ccs above zero can mark numerical stabilities>');
%        4;
%    end
%    gpu_ccForBlock{j} = dpktomo.match.aux.flipCC(gpu_ccForBlock{j},sizeTemplate);
    gpu_ccForBlock = dpktomo.match.aux.flipCC(gpu_ccForBlock,sizeTemplate);
    
%    j = j + 1;
%    if mod(i, 30) == 0 || i == NAngles
%        for j=1:length(gpu_ccForBlock)
%            ccForBlock{i-j + 1} = gather(gpu_ccForBlock{j});
%        end
%        j = 1;
%    end
    maxCC = max(maxCC,gpu_ccForBlock);
    
    indicesUpdate = find(maxCC==gpu_ccForBlock);
    
    if ~isempty(indicesUpdate)
        tdrotMatrix(indicesUpdate) = cast(myTriplet(1), 'int16');
        tiltMatrix(indicesUpdate)  = cast(myTriplet(2), 'int16');
        narotMatrix(indicesUpdate) = cast(myTriplet(3), 'int16');
    end
    
    iteration_end = toc(iteration_begin);
    iteration_time_sum = iteration_time_sum + iteration_end;
    if mod(i-1, 10) == 0
        fseek(time_file_id, 0, "bof");        
        fprintf(time_file_id, "%d", (iteration_time_sum/i) * (NAngles - i) + ((iteration_time_sum/i) * (NAngles) * length(obj.partition.tiles)));
    end
    
end
fclose(time_file_id);
fclose(iteration_file_id);

%for i=1:NAngles
%    myTriplet = triplets(i,:);
    
    
    % updates the accountance for found maxima of CC
%    gpu_ccForBlock_tmp = gpuArray(ccForBlock{i});
%    maxCC = max(maxCC,gpu_ccForBlock_tmp);
%    
%    indicesUpdate = find(maxCC==gpu_ccForBlock_tmp);
%    
%    if ~isempty(indicesUpdate)
%        tdrotMatrix(indicesUpdate) = cast(myTriplet(1), 'int16');
%        tiltMatrix(indicesUpdate)  = cast(myTriplet(2), 'int16');
%        narotMatrix(indicesUpdate) = cast(myTriplet(3), 'int16');
%    end
%end



ccForBlock=[];

totalTimeLapse   = etime(clock(), timeStart);

timePerAngle = (totalTimeLapse - setupTimeLapse)/NAngles;
o.e('  ... tile %d finished in %d seconds (%d for setup; %5.2f per triplet)',....
    {obj.tag,round(totalTimeLapse),round(setupTimeLapse),timePerAngle});

% writes result into the general tomogram
maximalCCFinal= -1*ones(size(maxCC),classUnderlying(maxCC));

% prepares for writting into a tile


;
f = 0.5;
obj.ccBinXIndices = (tx*f+1):(Nx-tx*f);
obj.ccBinYIndices = (ty*f+1):(Ny-ty*f);
obj.ccBinZIndices = (tz*f+1):(Nz-tz*f);


icx = obj.ccBinXIndices;
icy = obj.ccBinYIndices;
icz = obj.ccBinZIndices;

% adjusts for odd dimensions
if mbparse.isodd(tx)
    icx = icx+f;
end
if mbparse.isodd(ty)
    icy = icy+f;
end
if mbparse.isodd(tz)
    icz = icz+f;
end

obj.ccBinXIndices = icx;
obj.ccBinYIndices = icy;
obj.ccBinZIndices = icz;


maximalCCFinal(icx,icy,icz) = gather(maxCC(icx,icy,icz));



obj.binnedChunk = chunk;
obj.binnedCC    = cast(maximalCCFinal,'single');
obj.tdrot       = cast(gather(tdrotMatrix),'int16');
obj.tilt        = cast(gather(tiltMatrix),'int16');
obj.narot       = cast(gather(narotMatrix),'int16');
obj.writeOutput();

% deletes matrices that are not needed
obj.flush();
end