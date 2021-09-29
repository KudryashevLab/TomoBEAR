% addShifter
%  
function shifterStep = addShifter(obj,shifter,varargin)
library = obj;
w = obj.workflow;


%shifter = dpktilt.aux.align.pipeline.steps.Shifter(obj);
%obj.steps.addStep(shifter);
shifterStep = mboop.flows.stepTypes.DynamicStep(w);
shifterStep.identity.name     = 'shifter';
shifterStep.identity.pretty   = 'rough alignment'; %
shifterStep.identity.comment  = 'rough alignment';
shifterStep.computingFunction = @(x) localShifter(x,shifter);
library.registerStep(shifterStep);

% adds the input
shifterStep.status.addInputItem('selectedPeaksCloud');
shifterStep.status.addInputItem('nominalTiltAngles');

% adds the output
%shifterStep.status.addOutputItem('allRoughMarkers');

% adds a viewer to the step that uses this output
%datagate = w.io.gate('allRoughMarkers');
%viewer = datagate.inspector.viewerTracesSimplePlot(shifterStep);
%shifterStep.viewers.addItem(viewer);

o = w.dev.contents.markerIntermediateDataGateAddToStep(shifterStep);

% % adds a viewer predefined to use the video reader of the matrix
% viewer = w.dev.contents.getViewerForShapesOnMatrix(shifterStep,'videoRoughMarkers',....
%     datagate,'asStaticCloud',1,'title','All chains found by shifter');
% viewer.identity.pretty   = 'Show all chains in dmarkers [as non-editable]';


% adds  parameters
p = mbs.p.Scalar(800);
p.name    = 'maximalShift';
p.pretty  = 'maximal shift';
p.comment = 'In pixels, maximum shift expected among two micrographs';
shifterStep.addParameter(p);


p = mbs.p.Scalar(20);
p.name   = 'shiftInterval';
p.pretty = 'shift sampling interval';
p.comment = 'In pixels';
shifterStep.addParameter(p);

p = mbs.p.Scalar(20);
p.name   = 'maximalHysteresis';
p.pretty = 'maximal histeresis';
myComment = {'when a match is tracked back, the distance between'};
myComment{end+1} = ' - original point and ';
myComment{end+1} = ' - back tracked point ';
myComment{end+1} = 'should be below this value (in pixels of the working matrix)';
p.comment = myComment;
shifterStep.addParameter(p);


p = mbs.p.Switcher(1);
p.name    = 'skipManualDiscardsInShifts';
p.pretty  = 'Skip manually discarded tilts';
myComment = {'Tilts that have been prediscarded when setting the workflow will be skipped by default'};
shifterStep.addParameter(p);




function ok = localShifter(shifterStep,shifter)
ok =  false;
w = shifterStep.workflow;
%sfm = dpktilt.aux.index.cloudOverlap.Shifter(pof.getIndexedCloud);

% We accept that the shifter can be passed externally
% shifter              = w.operators.items.shifter; 


gatePeaks = w.io.gate('selectedPeaksCloud');
cloudSelectedPeaks   = gatePeaks.get();
cellSelectedPeaks    =  mbparse.cells.indexedCloud2cell(cloudSelectedPeaks,1:2,3); 
shifter.coordinates  = cellSelectedPeaks;


% prepares the parameters in the shifter
shifterStep.parameters.dump();
shifter.xShiftsSample = -maximalShift:shiftInterval:maximalShift;
shifter.yShiftsSample = -maximalShift:shiftInterval:maximalShift;


shifter.skippingIndicesIsActive = skipManualDiscardsInShifts;
if skipManualDiscardsInShifts
    
    shifter.indicesToSkip = w.io{'discardedTiltIndices'};
    
else
    shifter.indicesToSkip = [];
end


shifter.compute('mw',w.settings.computing.cpus.value);
shifter.matches2allTracks();

% creates a markerset
roughMarkers =  shifter.getMarkerSet();

gateTilts = w.io.gate('nominalTiltAngles');
tilts = gateTilts.get();
roughMarkers.nominalTiltAngles = tilts;

%gateRoughMarkers = w.io.gate('allRoughMarkers');
%gateRoughMarkers.data = roughMarkers;

w.dev.contents.markerIntermediateDataGateRegisterMarkers(shifterStep,roughMarkers);

%w.io.updateCurrentMarkers(roughMarkers,'disk',1);
ok = true;