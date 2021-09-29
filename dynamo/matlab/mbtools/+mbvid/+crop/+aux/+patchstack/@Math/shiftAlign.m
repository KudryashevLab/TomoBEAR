% shiftAlign
%
% FLAGS
%
%
%     'updateShifts':  changes the shifts in the patch stack
%
%     'gaussWidthForOutlierRemoval'
%
%
%     'iterations'
%


function [outputStack,o] = shiftAlign(obj,varargin)
o = mbs.o;
stack       = obj.parent;
outputStack = cloneof(stack);
o.addprop('peaks');
o.addprop('shifts');
o.addprop('cc');
o.addprop('ccmatrix');
o.addprop('iterationAverages');
o.addprop('iterationStacks');
o.iterationAverages = {};
o.iterationStacks   = {};

%o =mbs.o;
%%%% Standard creation of input parser
p = mbparse.ExtendedInput();
if mbparse.isodd(length(varargin));
    varargin = mbparse.ExtendedInput.setFirstFlag('template',varargin);
end
p.addParamValue('iterations',0,'short',{'i','ite'});
p.addParamValue('template',[],'short','t');
p.addParamValue('bandpass',[],'short',{'b','band'});
p.addParamValue('limits',[],'short',{'lm','lim'});
p.addParamValue('mask',[],'short','m');
p.addParamValue('getcc',true,'short','cc');
p.addParamValue('limitAroundPreviousCenters',false,'short','lpc');
p.addParamValue('updateShifts',false);
p.addParamValue('gaussWidthForOutlierRemoval',3,'short','qwor');
p.addParamValue('recentering',false);
p.addParamValue('fast',false);
p.addParamValue('v',true);

p = mbparse.multicore.addParser(p);
%p.addParamValue('v',true);
%%% response to search codes
%p.lookForCodes(XX); % here put the name of the first input variable
if p.forceErrorInCaller;error('... aborting');end
if p.forceReturnInCaller;disp('... returning');return;end
q = p.getParsedResults(varargin{:});
o.verbosity = q.v;
%o=mbparse.output(q.handles);


if isempty(q.template)
    myTemplate = obj.getAverage();
else
    myTemplate = q.template;
end

if iscell(q.template)
    templateInput = q.template;
    firstValid = 0;
    for i=1:length(templateInput)
        if ~isempty(templateInput{i})
            firstValid = i;
            break
        end
        
    end
    if firstValid==0
        disp('Cell of templates is empty');
        return
    end
    templateSize = size(q.template{firstValid});
else
    templateSize  = size(myTemplate);
    templateInput = myTemplate;
end



if ~iscell(templateInput) && ~isnumeric(templateInput);
    error('Invalid template');
end

if q.recentering
    [templateInput] =dpktilt.aux.detect.centering.centerOfMass(templateInput,'v',0);
end


%
% First iteration
%
o.e('Starting first iteration ');
t1  = cputime();
[outputStack,o] = singleIteration(obj,stack,q,o,templateSize,templateInput);
tEnd = cputime()-t1;
o.e('  - Time (s) in first iteration: %5.2f',tEnd);
if q.iterations==0
    o.e('Shift alignment finished');
    return
end

newStack = cloneof(outputStack);
nIterations = q.iterations-1;
for i=1:nIterations
    o.iterationAverages{end+1} = templateInput;
    o.iterationStacks{end+1}   = newStack;
    
    o.e('Starting refinement iteration %d',i+1);
    t1  = cputime();
    previousStack = cloneof(newStack);
    
    if iscell(templateInput)
        newTemplate  = previousStack.math.getAverage('byTracks',true,'interpolate',true);
    else
        newTemplate  = previousStack.math.getAverage('interpolate',true);
    end
    
    if q.recentering
        [newTemplate] =dpktilt.aux.detect.centering.centerOfMass(newTemplate,'v',0);
    end
    [newStack,o] = singleIteration(obj,previousStack,q,o,templateSize,newTemplate);
    tEnd = cputime()-t1;
    
    shiftDifference = newStack.shift-previousStack.shift;
    x = shiftDifference(:,1).^2;
    y = shiftDifference(:,2).^2;
    r = sqrt(x+y);
    residual = mean(r);
    o.e('  - Time (s) in iteration %d: %5.2f',{i,tEnd});
    o.e('  - Mean change in shifts: %5.2f',residual);
    templateInput = newTemplate;
end
4;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%               ITERATION SUBROUTINE
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function [newStack,o] = singleIteration(obj,stack,q,o,templateSize,templateInput);
newStack = cloneof(stack);

if isempty(q.mask)
    L = templateSize(1);
    myMask = dynamo_circle(floor(L/2)-1,L);
else
    myMask = q.mask;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%               COMPUTES the ccmatrix
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


if iscell(templateInput)
    templateArray = q.template;
    nz = size(stack.track,3);
    
    tic
    ccMatrix = fastCC(templateSize,templateArray,stack.matrix,stack.track);
    toc;
    4;
    if q.fast
        tic
        ccMatrix = fastCC(templateSize,templateArray,stack.matrix,stack.track);
        toc;
        4;
    else
        tic;
        ccMatrix = zeros(templateSize(1),templateSize(2),nz,'single');
        
        for i=1:length(q.template)
            indices     = find(stack.track==i);
%             if isempty(indices)
%                 continue;
%             end
            submatrix   = stack.matrix(:,:,indices);
%             if isempty(submatrix)
%                 continue;
%             end
            subCCMatrix = template2ccmatrix(templateInput{i},myMask,submatrix,q);
            ccMatrix(:,:,indices) = subCCMatrix;
            4;
        end
        toc;
    end
    
else
    %
    % single template
    %
    submatrix = stack.matrix;
    ccMatrix = template2ccmatrix(templateInput,myMask,submatrix,q);
end

o.ccmatrix = ccMatrix;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%               Analyzes the ccmatrix
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



[mx,my,mz] = size(ccMatrix);
% impose limits
if ~isempty(q.limits)
    
    limitingMask = double(dynamo_circle(q.limits,templateSize));
    limitingMask(find(limitingMask<1)) = 0;
    
    limitingMatrix = repmat(limitingMask,[1,1,mz]);
    if q.limitAroundPreviousCenters
        if size(stack.shifts,1)~=mz
            error('Shifts are not present in original patch stack');
        end
        limitingMatrix = dpk2d.move.stack.fourier(limitingMatrix,stack.shifts);
    else
        
    end
    ccMatrixBuffer = ccMatrix;
    ccMatrix       = ccMatrixBuffer.*limitingMatrix;
    
else
    %o.assignprop('limitedCCmatrix', ccMatrix);
end
o.assignprop('limitedCCmatrix', ccMatrix);



centerTemplate = dpkgeom.conventions.center.dynamo2d(templateSize);


% computes the actual positions of the first peak
peak = zeros(mz,2);
cc   = zeros(mz,1);

outlierRemoval = true;
if outlierRemoval
    [peak,cc] = mbmath.peaks2d.robustPeaks(ccMatrix,....
        'gaussWidth',q.gaussWidthForOutlierRemoval);
else
    for i=1:mz;
        [peakPosition,peakValue] = mbmath.peaks2d.subpixelSpline(ccMatrix(:,:,i));
        peak(i,:) = peakPosition;
        cc(i)     = peakValue;
    end
end

o.shifts =  peak - centerTemplate;
o.peaks   = peak;
o.cc      = cc;

if q.updateShifts
    obj.parent.shift = o.shifts;
    obj.parent.cc    = cc;
end

%
newStack.shift = o.shifts;
newStack.cc    = cc;

if size(newStack.shift,1)~=size(newStack.center,1)
    error('Something went wrong, dimension of centers and shifts do not match!');
end

o.ok = true;

%
% AUXILIARY FUNCTIONS
%
function ccMatrix = template2ccmatrix(myTemplate,myMask,submatrix,q);
myTemplate(isnan(myTemplate)) = 1;



goldFinder = dpktilt.aux.detect.GoldFinder();
goldFinder.switchAutosave(false);
goldFinder.mask = myMask;


if isempty(submatrix)
    o = mbs.o();
    o.error(5);
    o.e('The ''matrix'' property with the actual patch data is not ready in this patch stack object.');
    o.e('Cannot align translationally against anything.');
    return
end

if isempty(q.bandpass)
    finalMatrix   = submatrix;
    finalTemplate = myTemplate;
else
    finalMatrix   = dpktilt.math.bandpass(submatrix,q.bandpass);
    finalTemplate = dynamo_bandpass_nyquist(myTemplate,q.bandpass);
end


goldFinder.tiltMatrix       = finalMatrix;
goldFinder.originalTemplate = finalTemplate;

[mx,my,mz] = size(goldFinder.tiltMatrix);
[sx,sy]    = size(myTemplate);

if any(size(myTemplate)>[mx,my])
    o = mbs.o();
    o.e(' Size template: %d %d',{sx sy});
    o.e(' Size patch: %d %d',{mx my});
    o.e('Template is bigger than patch. Returning.');
    return
end
if any(size(myTemplate)~=[mx,my])
    %o.e(' Size template: %d %d',{sx sy});
    %o.e(' Size patch: %d %d',{mx my});
    %o.e('Embedding template and match in bigger images.');
    
    
    canvas      = zeros(mx,my);
    newTemplate = dpk2d.embed.simple(finalTemplate,canvas);
    newMask     = dpk2d.embed.simple(myMask,canvas);
    goldFinder.originalTemplate = newTemplate;
    goldFinder.mask   = newMask;
    
    finalTemplate = newTemplate;
    [sx,sy] = size(finalTemplate);
end


check = goldFinder.computeCCMatrix('matlabWorkers',q.matlab_workers,....
    'verbosityCheckPool',0);
if ~check.ok
    o.error(5);
    o.e('Could not compute ccmatrix aligning a marker set');
    return
end


ccMatrix   = goldFinder.ccmatrix;

function ccMatrix = fastCC(templateSize,templateArray,matrix,trackIndices);
nz = size(matrix,3);
templateMatrix =  zeros(templateSize(1),templateSize(2),nz,'single');

for i=1:length(templateArray)
    thisTemplate = templateArray{i};
    
    if isempty(thisTemplate)
        disp(sprintf('<fastCC> not available template %d',i));
        continue;
    end
    
    
    indices     = find(trackIndices==i);
    if isempty(indices)
        continue;
    end
    
    templateMatrix(:,:,indices) = repmat(thisTemplate,[1,1,length(indices)]);
    
    
    
end

%
D = fft2(matrix);          % DATA
T = fft2(templateMatrix);  % TEMPLATE
ccMatrix = real(fftshift(fftshift(ifft2(D.*conj(T)),1),2));
4;



