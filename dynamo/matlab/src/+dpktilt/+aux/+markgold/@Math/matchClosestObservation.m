% matchClosestObservation
%
% FLAGS
%
% 'minimumDistance'  
% 'exclusionDistance'  
% 
% Used when the parenting shape set is assumed to come from a reprojection.
function ssOut = matchClosestObservation(obj,beadCloudCell,varargin)

ssIn  = obj.parent;
ssOut = clone(ssIn);
ssOut.nominalTiltAngles = ssIn.nominalTiltAngles;

% emptyCell = cell(1,ssOut.NumberTilts());
% for i=1:length(ssOut.shapes)
%     ssOut.shapes(i).coordinates = emptyCell;
% end

%o =mbs.o;
%%%% Standard creation of input parser
p = mbparse.ExtendedInput();
p.addParamValue('minimumDistance',10,'short','md');
p.addParamValue('exclusionDistance',20,'short','ed');
p.addParamValue('excludeIfSeveralBeads',true,'short','eis');
p.addParamValue('micrographSize',[],'short','ms');
%p.addParamValue('',[]);
%p.addParamValue('handles','screen');
%p.addParamValue('v',true);
%%% response to search codes
%p.lookForCodes(XX); % here put the name of the first input variable
if p.forceErrorInCaller;error('... aborting');end
if p.forceReturnInCaller;disp('... returning');return;end
q = p.getParsedResults(varargin{:});
%o=mbparse.output(q.handles);

matchedCloud  = zeros(0,4);
availableTils = 1:ssIn.numberTilts();
projectionCloudFull   = ssIn.grepIndexedCloud();

nNaN = length(find(isnan(projectionCloudFull)));

if nNaN~=0
   error('Cloud of projections contain %d NaN entries',nNaN);
end

for iTilt = 1:ssIn.numberTilts()
    
%     if iTilt==3
%         4;
%         end
    
    projectionCloud   = ssIn.grepIndexedCloud('frames',iTilt);
    projectionCloudXY = projectionCloud(:,1:2);
    beadCloud         = beadCloudCell{iTilt};
    
    indicesMatchedBeads = dpktilt.aux.index.reprojection.matchClouds(.....
        projectionCloudXY,beadCloud,....
        'minimumDistance',q.minimumDistance,.....
        'exclusionDistance',q.exclusionDistance,....
        'excludeIfSeveralBeads',q.excludeIfSeveralBeads,...
        'micrographSize',q.micrographSize);
    
     % 
     indicesMarkerWithMatch = find(~isnan(indicesMatchedBeads));
     
     % MY FIX (BEGIN)
     if isempty(indicesMarkerWithMatch)
         indicesMarkerWithMatch = zeros([0 1], "double");
     end
     % MY FIX (END)
     
     indicesSelectedBeads = indicesMatchedBeads(indicesMarkerWithMatch);
     frameVector  = iTilt*ones(length(indicesMarkerWithMatch),1);
     newCloudTilt = [beadCloud(indicesSelectedBeads,1:2),frameVector,indicesMarkerWithMatch];
    
     
     check = true;
     if check
         membership = ismember(newCloudTilt(:,1:2),beadCloud,'rows');
         if any(~membership)
            error('something went wrong'); 
         end
     end
     
     testing = false;
     if testing
         
         
         if iTilt == 41;
             figure;
             %h1 = mbgraph.plot(newCloudTilt,'cols',1:2,'Marker','x','LineStyle','none','MarkerEdgeColor','r');
             h2 = mbgraph.plot(beadCloud,   'cols',1:2,'Marker','o','LineStyle','none','MarkerEdgeColor','b');
             h3 = mbgraph.plot(projectionCloudXY,   'cols',1:2,'Marker','s','LineStyle','none','MarkerEdgeColor','g');
             keyboard;
         end
     end
     matchedCloud = cat(1,matchedCloud,newCloudTilt);
     
    
end


%
ssOut.setIndexedCloud(matchedCloud,'numberFrames',length(ssOut.nominalTiltAngles));

% disp('deleteme');
% for i=1:length(ssOut.shapes)
%     disp(length(ssOut.shapes(i).coordinates));
% end




