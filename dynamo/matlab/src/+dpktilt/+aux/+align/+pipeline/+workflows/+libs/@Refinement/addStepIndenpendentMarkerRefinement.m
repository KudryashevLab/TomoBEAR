% addStepTraceGapFiller
%  
%  INPUT
%  
%  FLAGS
%  
%  OUTPUT
%  
%  SYNTAX
%  
function addStepIndenpendentMarkerRefinement(obj,varargin)
library = obj;
w = library.workflow;
%o =mbs.o;
%%%% Standard creation of input parser
p = mbparse.ExtendedInput();
p.addParamValue('name','independentMarkerRefinement');
%p.addParamValue('handles','screen');
%p.addParamValue('v',true);
%%% response to search codes
%p.lookForCodes(XX); % here put the name of the first input variable
if p.forceErrorInCaller;error('... aborting');end
if p.forceReturnInCaller;disp('... returning');return;end
q = p.getParsedResults(varargin{:});
%o=mbparse.output(q.handles);

newStep = mboop.flows.stepTypes.DynamicStep(w);
newStep.identity.name   = q.name;
newStep.identity.pretty = 'independent marker refinement';
newStep.computingFunction = @(x) localIndependentTraceRefinement(x,library);
newStep.identity.comment  = {'Refines each observation against the average in the trace'};




newParameter = mbs.p.Switcher(true);
newParameter.name    = 'recenterAverages';
newParameter.pretty  = 'recenter averages';
newParameter.comment = 'recenters the markers averages against their respective center of mass';
newStep.parameters.addParameter(newParameter);

newParameter = mbs.p.Scalar(1);
newParameter.name    = 'iterationsRefineAverages';
newParameter.pretty  = 'refinement iterations';
newParameter.comment = 'iterates the  alignment procedure';
newStep.parameters.addParameter(newParameter);

newParameter = mbs.p.Scalar(1);
newParameter.name    = 'gaussfiltOutlierDetectionCC';
newParameter.pretty  = 'gaussian width for cc';
newParameter.comment = {'width of gaussian filter',....
    'used to get rid of spureous jumps in the cross correlation when locating the gold beads'};
newStep.parameters.addParameter(newParameter);


% new data gate: selected peaks
selectedPeaksGate = mbp.datagate.FileGate('inspectorClass','Stack');
selectedPeaksGate.identity.name   ='partialMarkerAverages';
selectedPeaksGate.identity.pretty = 'partial marker averages';
selectedPeaksGate.location.locator = {w,[string(filesep),'refinement',string(filesep),'partialMarkerAverages.em']}; % Not scaled, comes in full size
library.registerDataGate(selectedPeaksGate);


selectedPeaksGate = mbp.datagate.FileGate('inspectorClass','Stack');
selectedPeaksGate.identity.name ='recenteredMarkerAverages';
selectedPeaksGate.identity.pretty = 'partial marker averages recentered';
selectedPeaksGate.location.locator = {w,[string(filesep),'refinement',string(filesep),'recenteredMarkerAverages.em']}; % Not scaled, comes in full size
library.registerDataGate(selectedPeaksGate);


%
% IO
%
newStep.status.addInputItem('workingMarkers');
newStep.status.addOutputItem('workingMarkers');


library.registerStep(newStep);
o = w.dev.contents.markerIntermediateDataGateAddToStep(newStep);

function ok = localIndependentTraceRefinement(thisStep,library)
ok = false;
w = library.workflow;

workingMarkers = w.io{'workingMarkers'};
stepMarkers = clone(workingMarkers);

%w.oh('Sorry, this code has not yet been filled.','icon','atwork','tb',2);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%%  Crops patch stack
%%%

patchStack = w.dev.contents.cropPatchStack();

if isempty(patchStack)
   w.oh('Could not extract stack of gold bead patches at full Resolution','icon','error','tb',3);
   return 
end   

% DUMP PARAMETERS in memory
thisStep.parameters.dumpParameters();
%
%     iterationsRefineAverages: [1×1 mbs.p.Scalar]
%     gaussfiltOutlierDetectionCC: [1×1 mbs.p.Scalar]
%                recenterAverages:

o = mbs.o();
o.e('parameter <gaussfiltOutlierDetectionCC> not used yet');

currentPatchStack = cloneof(patchStack);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% create new markers
%%%
currentTemplates = currentPatchStack.math.getAverage('byTracks',true,'move',true);

for i = length(currentTemplates):-1:1
    if isempty(currentTemplates{i})
        currentTemplates(i) = [];
    end
end

if isempty(currentTemplates)
    w.oh('Marker averages seem to be empty','icon','error','tb',3);
    return
end


[newStack,check] = currentPatchStack.math.shiftAlign(.....
    'template',currentTemplates,'ite',iterationsRefineAverages,....
    'recentering',recenterAverages);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% updates the  markers in this step
%%%

newCloud = newStack.getIndexedCloud();

if isempty(newCloud)
    error('<What!!!???>');
    w.oh('Something went wrong, new cloud of observations disappeared');
   return 
end
stepMarkers.setIndexedCloud(newCloud);

w.dev.contents.markerIntermediateDataGateRegisterMarkers(thisStep,stepMarkers);
ok = true;