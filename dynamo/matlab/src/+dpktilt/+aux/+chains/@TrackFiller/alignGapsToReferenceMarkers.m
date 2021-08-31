% alignGapsToReferenceMarkers
%  
%  INPUT
%  
%  FLAGS
%  
%  OUTPUT
%  
%  SYNTAX
%  
function o = alignGapsToReferenceMarkers(obj,varargin)
o = mbs.o();
o.addprop('gapCloud');
%o =mbs.o;
%%%% Standard creation of input parser
p = mbparse.ExtendedInput();
p = mbparse.multicore.addParser(p);
p.addParamValue('gaussWidthOutlierRemoval',5);
p.addParamValue('thresholdDistanceFromCenter',5);
p.addParamValue('plotSketch',false);
p.addParamValue('fastCC',true,'short','fast');
%p.addParamValue('handles','screen');
%p.addParamValue('v',true);
%%% response to search codes
%p.lookForCodes(XX); % here put the name of the first input variable
if p.forceErrorInCaller;error('... aborting');end
if p.forceReturnInCaller;disp('... returning');return;end
q = p.getParsedResults(varargin{:});
%o=mbparse.output(q.handles);

referencePatchStack = obj.coherenceReference.defaultPatchStack;
templates = referencePatchStack.math.getAverage('byTracks',true,'interpolate',true);

gapPatchStack = obj.coherenceGap.defaultPatchStack;
[alignedGap,check] = gapPatchStack.math.shiftAlign('template',templates,....
    'matlab_workers',q.matlab_workers,'fast',q.fastCC);

%%
% gets rid of outliers in ccMatrix
%
ccMatrix = check.ccmatrix;
ccMatrixNoOutliers = dpktilt.aux.detect.centering.removeOutliersFromCC(ccMatrix,....
    'gaussWidth',q.gaussWidthOutlierRemoval);
ccMatrixFiltered   = dpktilt.apply(ccMatrixNoOutliers,@(x)imgaussfilt(x,1),'mw',q.matlab_workers);

% peaks
r = dpktilt.apply(ccMatrixFiltered,@(x)mbmath.peaks2d.subpixelSpline(x),'mw',q.matlab_workers);

center = dpkgeom.conventions.center.dynamo2d(size(ccMatrixFiltered(:,:,1)));

realShift      = gapPatchStack.shift+r-center;
particleCenter = gapPatchStack.center+realShift;
normRealShift = mbmath.norm(realShift);

threshold = q.thresholdDistanceFromCenter;
indicesGood = find(normRealShift<=threshold);

oldCloud = gapPatchStack.getIndexedCloud();
%%% OWN FIX
indicesGood = indicesGood(indicesGood < size(oldCloud,1));
%%%
goodShift   = realShift(indicesGood,:);
goodCenter  = particleCenter(indicesGood,:);




newCloud = oldCloud(indicesGood,:);
newCloudCorrected = newCloud;

%%% OWN FIX
if ~isempty(newCloudCorrected)
    newCloudCorrected(:,1:2) = goodCenter(:,:);
end
%%%

lengthExcluded = size(oldCloud,1) - size(newCloudCorrected,1);
disp(sprintf('  <gap filling> Excluded reprojections: %d',lengthExcluded));

o.gapCloud = newCloudCorrected;


o.ok = true;
4;

