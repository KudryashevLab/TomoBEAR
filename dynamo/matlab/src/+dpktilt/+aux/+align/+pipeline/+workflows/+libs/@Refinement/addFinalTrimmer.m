% addFinalTrimmer
%  
%  INPUT
%  
%  FLAGS
%  
%  OUTPUT
%  
%  SYNTAX
%  
function addFinalTrimmer(obj,varargin)
library = obj;
localTrimmer = dpktilt.aux.markgold.Trimmer();


w  = obj.workflow;
io = obj.io;
myStep = mboop.flows.stepTypes.DynamicStep(w);
myStep.identity.name     = 'trimMarkers';
myStep.identity.pretty   = 'trim markers';
myStep.computingFunction = @(x) executeLocalTrimmerAction(myStep,library);

% copies the parameters of the trimmer
params = localTrimmer.parameters.getParameters();
myStep.addParameter(params);

if ~isprop(myStep.dev,'localTrimmer')
    addprop(myStep.dev,'localTrimmer');
else
    if ~isempty(myStep.dev.localTrimmer)
        mbgraph.delete(myStep.dev.localTrimmer);
    end
end
myStep.dev.localTrimmer = localTrimmer;

library.registerStep(myStep);
o = w.dev.contents.markerIntermediateDataGateAddToStep(myStep);

%
% IO
%
myStep.status.addInputItem('discardedTiltIndices');
myStep.status.addInputItem('workingMarkers');
myStep.status.addOutputItem('workingMarkers');

function ok = executeLocalTrimmerAction(myStep,library);
w = library.workflow;
localTrimmer = myStep.dev.localTrimmer;

workingMarkers = w.io{'workingMarkers'};

localTrimmer.markers = clone(workingMarkers);

fitterGate = w.io.gate('workingFitter');
myFitter  = fitterGate.get();
if mbparse.isUndefined(myFitter.traceSet.nominalTiltAngles);
    error('Undefined tilt angles');
end

localTrimmer.fitter  = myFitter;
o = localTrimmer.trim();
%%% OWN FIX
%if ~o.ok
%    o.e('Trimmer did not work');
%   return 
%end
%%% OWN FIX
newCloud = localTrimmer.markers.getIndexedCloud();
if isempty(newCloud)
    ok = true;
    w.oh('No markers left, trimming option will not be used','icon','warning','tb',2);
    return
end
stepMarkers = localTrimmer.markers;
o.e('Trimming perfomed');
mbdisp(stepMarkers.io.infoLines());

w.dev.contents.markerIntermediateDataGateRegisterMarkers(myStep,stepMarkers);
ok = true;



