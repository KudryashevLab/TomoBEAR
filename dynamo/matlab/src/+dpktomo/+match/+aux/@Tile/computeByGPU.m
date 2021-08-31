% computeByGPU
%  
%  INPUT
%  
%  FLAGS
%  
%  OUTPUT
%  
%  SYNTAX
%  
function computeByGPU(obj,varargin)
o = mbs.o;
timeStart = clock();
o.e(' Computing tile %d in GPU',obj.tag);
o.e('   -Range (original block): %s',obj.prettyRange());
o.e('   -Range (binned block)  : %s',obj.binnedTile.prettyRange());

operationalData = obj.process.operationalData;

chunk       = obj.getSourceBlock(); % includes binning
gChunk       = gpuArray(chunk);

% binnig has been taken into account in the preoperative setup
gTemplate    = gpuArray(operationalData.template);
gMask        = gpuArray(operationalData.mask);
gfMaskCorner = gpuArray(fftshift(operationalData.fmask));

triplets     = operationalData.triplets;

[Nx,Ny,Nz] = size(gChunk);
[tx,ty,tz] = size(gTemplate);
sizeTemplate = [tx,ty,tz];
sizeData     = [Nx,Ny,Nz];

gRotatedTemplateCanvas = zeros(Nx,Ny,Nz,class(gChunk));
gRotatedMaskCanvas     = zeros(Nx,Ny,Nz,class(gChunk));

normTemplate = operationalData.normTemplate;
Nmask        = operationalData.NMask;

%
chunkNormalized = dynamo_normalize_roi(gChunk);

chunkNormalized = gpuArray(chunkNormalized);

conjP        = conj(fftn(chunkNormalized));
conjPSquared = conj(fftn(chunkNormalized.^2));
clear chunkNormalized;

% trackers
maximalCC    = -1*ones(Nx,Ny,Nz,'single');
tdrotMatrix  = 0*ones(Nx,Ny,Nz,'int16');
tiltMatrix   = 0*ones(Nx,Ny,Nz,'int16');
narotMatrix  = 0*ones(Nx,Ny,Nz,'int16');

if any([tx,ty,tz]>[Nx,Ny,Nz])
   disp('Template is bigger than chunk!');
   return
end


NAngles = size(triplets,1);
setupTimeLapse   = etime(clock(), timeStart);

% defines elements that will be updated 
gRotatedTemplate = (gTemplate);
gRotatedMask     = (gMask);


%
% Creates the kernel
%
kernelRotation = parallel.gpu.CUDAKernel('rotateSingle.ptx','rotateSingle.cu','rotation');
N = size(gRotatedTemplate,1);

kernelRotation.GridSize = [N,N,1];
kernelRotation.ThreadBlockSize = N;


%
% computations
%

for i=1:NAngles;
    
    myTriplet = triplets(i,:);
   
    roma  = dynamo_euler2matrix(myTriplet)'; % attention to the translation!
    rotationMatrix = cast(roma(:),'single');
    gRotatedTemplate = feval(kernelRotation,gRotatedTemplate,gTemplate,N,rotationMatrix);
    
    gRotatedTemplate = dynamo_nan(gRotatedTemplate);
    gRotatedMask     = dynamo_nan(gRotatedMask);
    
    % recompute mask
    gRotatedMask = dynamo_binarize(gRotatedMask,0.5);
    gIndMask     = find(gRotatedMask);
    Nmask       = length(find(gIndMask));
    
    if Nmask == 0
       disp('-------------------------------------------------');
       disp('Mask does not contain any non-zero points!!');
       disp('Switching off local masking....');
       gRotatedMask(:,:,:)=1;
       indMask     = find(gRotatedMask);
       Nmask       = length(find(indMask));
       
    end
    
    
    if obj.process.settings.applyFmask.value
        gRotatedTemplate = fftn(gRotatedTemplate);
        gRotatedTemplate = real(ifftn(gRotatedTemplate.*gfMaskCorner));
    end
    
    % recompute norm of template
    
    if std(gRotatedTemplate(find(gRotatedMask)))<eps
       disp('-------------------------------------------------');
       disp('Mask does not see any intensity variance');
       disp('Switching off local masking....');
       gRotatedMask(:,:,:)=1;
       gIndMask     = find(gRotatedMask);
       Nmask       = length(find(gIndMask));
    end
    
   
    gRotatedTemplate = dynamo_normalize_roi(gRotatedTemplate,gRotatedMask);
    normTemplate    = sqrt(sum(sum(sum(gRotatedTemplate(gIndMask).^2))));
    if isnan(normTemplate)
        error('Template norm is NaN!!!');
    end
    

    gRotatedTemplate = gRotatedTemplate.*gRotatedMask;
    
    gRotatedTemplateCanvas(1:tx,1:ty,1:tz) = gRotatedTemplate;
    gRotatedMaskCanvas(1:tx,1:ty,1:tz)     = gRotatedMask;
    
     
    
    ccForBlock = dpktomo.match.aux.ccCore(gRotatedTemplateCanvas, gRotatedMaskCanvas,...
        conjP,conjPSquared,Nmask,normTemplate);
    
    
    if max(ccForBlock(:)) >1
        disp('<attention, ccs above zero can mark numerical stabilities>');
        4;
    end
   
    ccForBlock = dpktomo.match.aux.flipCC(ccForBlock,sizeTemplate);
    
    
    % updates the accountance for found maxima of CC
    maximalCC = max(maximalCC,ccForBlock);
    

    
    indicesUpdate = find(maximalCC==ccForBlock);
    
    if ~isempty(indicesUpdate)
        tdrotMatrix(indicesUpdate) = cast(myTriplet(1),'int16');
        tiltMatrix(indicesUpdate)  = cast(myTriplet(2),'int16');
        narotMatrix(indicesUpdate) = cast(myTriplet(3),'int16');
    end
end
ccForBlock=[];

totalTimeLapse   = etime(clock(), timeStart);

timePerAngle = (totalTimeLapse - setupTimeLapse)/NAngles;
o.e('  ... tile %d finished in %d seconds (%d for setup; %5.2f per triplet)',....
    {obj.tag,round(totalTimeLapse),round(setupTimeLapse),timePerAngle});

% writes result into the general tomogram
maximalCCFinal= -1*ones(size(maximalCC),class(maximalCC));

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


maximalCCFinal(icx,icy,icz) = maximalCC(icx,icy,icz);



obj.binnedChunk = chunk;
obj.binnedCC    = single(gather(maximalCCFinal));
obj.tdrot       = cast(tdrotMatrix,'int16');
obj.tilt        = cast(tiltMatrix,'int16');
obj.narot       = cast(narotMatrix,'int16');
obj.writeOutput();

% deletes matrices that are not needed
obj.flush();
