% This is a transition procedure for the GPU
% At some point we will introduce a native GPU resampling, momentarily we just pre-resample the data
% and store it somewhere in the temporal directories.
%
% Funtionalities:
%
% 1 - Resampling of data
%
% 2 - Creation of ref cards (shouldn't it be done in the setup itself?)



% Author: Daniel Castano-Diez, April 2012 (daniel.castano@unibas.ch)
% Copyright (c) 2012 Daniel Castano-Diez and Henning Stahlberg
% Center for Cellular Imaging and Nano Analytics
% Biocenter, University of Basel
%
% This software is issued under a joint BSD/GNU license. You may use the
% source code in this file under either license. However, note that the
% complete Dynamo software packages have some GPL dependencies,
% so you are responsible for compliance with the licenses of these packages
% if you opt to use BSD licensing. The warranty disclaimer below holds
% in either instance.
%
% This complete copyright notice must be included in any revised version of the
% source code. Additional authorship citations may be added, but existing
% author citations must be preserved.
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  2111-1307 USA


function dynamo__iteration_setup_gpu(filecard_ite,runtimeManager)

scard = dynamo_read(filecard_ite);
vpr   = dynamo_vpr_load(scard.name_project);


% reads the basic facts
ite  = scard.database_ite;
nref = scard.nref;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 1 - Eventual resampling of data particles
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[folder_data_resampled,shifts_shrink_factor]=local_iteration_setup_gpu_resizing(vpr,scard);

DEBUGGING_ignore_resampling = true;
if DEBUGGING_ignore_resampling
    folder_data_resampled = vpr.folder_data;
end
    
    


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 2   Assignation of particles to GPUs
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

local_iteration_setup_gpu_assign(vpr,scard,runtimeManager);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 3  Creation of GPU-specific iterefcards
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

local_iteration_setup_gpu_update_iterefcards(vpr,scard,ite,nref,folder_data_resampled,shifts_shrink_factor);


%
%  END MAIN FUNCTION
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




function local_iteration_setup_gpu_update_iterefcards(vpr,scard,ite,nref,folder_data_resampled,shifts_shrink_factor);

files_scard_iteref=dynamo_database_locate('card_iteref',vpr,'ite',ite,'ref',1:nref);
files_scard_iteref=cell_checkin(files_scard_iteref);


currentRefs = dpkproject.pipeline.getSurvivingReferences(vpr,ite);
if isempty(currentRefs)
    error('No references to proceed. Project shoudl be complete by now.');
end


%  loops on valid referecences

for iref=1:nref
    
    if ~ismember(iref,currentRefs);continue;end
    
    % updates in the scard_iteref all the concepts that will be needed
    % in GPU-style computations
    
    scard_iteref{iref}=scard;
    
    scard_iteref{iref}.database_ref=iref;
    
    % data might have been pre-rescaled
    scard_iteref{iref}.database_gpu_folder_data_iteration = folder_data_resampled;
    
    % templates might have been pre-rescaled and symmetrized:
    location_template = dynamo_database_locate('starting_reference_transformed',vpr,'ite',ite,'ref',iref);
    scard_iteref{iref}.database_gpu_file_template_iteration = location_template;
    
    % fmask of tempalte might have been pre-rescaled and symmetrized:
    location_fmask = dynamo_database_locate('fmask_starting_reference_transformed',vpr,'ite',ite,'ref',iref);
    scard_iteref{iref}.database_gpu_file_fmask_iteration = location_fmask;
    
    % misk might have been pre-rescaled:
    location_mask = dynamo_database_locate('mask_transformed',vpr,'ite',ite);
    scard_iteref{iref}.database_gpu_file_mask = location_mask;
    
    
    % which tags are assigned to the reference
    % ATTENTION: HERE I AM ASSUMING WORK WITH SINGLE CPU
    % 'gpu' 0 is just an arbitrary value
    %
    % This hard coding must match the settings of the GPU application
    folder_assign_gpu=dynamo_database_locate('assign_gpu',vpr,'proc',0,'ref',iref,'gpu',0,'ite',ite,'folder',true);
    
    mark_iteref=['ite_',num2strtotal(ite,4),'_ref_',num2strtotal(iref,3),'_'];
    
    file_root_assign_gpu=fullfile(folder_assign_gpu,['assign_gpu_proc_00000_',mark_iteref,'gpu_']);
    scard_iteref{iref}.database_gpu_root_file_tags=file_root_assign_gpu;
    
    % fors sets of particles
    file_root_assign_gpuParticleList=fullfile(folder_assign_gpu,['assign_gpu_particleList_proc_00000_',mark_iteref,'gpu_']);
    scard_iteref{iref}.database_gpu_root_file_particleList=file_root_assign_gpuParticleList;
    
    
    
    % where ptable of particles will be written
    ptable_folder=dynamo_database_locate('starting_ptable',vpr,'ite',ite,'tag',1,'ref',1,'folder',true);
    scard_iteref{iref}.database_gpu_starting_ptable_root=fullfile(ptable_folder,['starting_ptable_',mark_iteref,'tag_']);
    scard_iteref{iref}.database_gpu_refined_ptable_root=fullfile(ptable_folder,['refined_ptable_',mark_iteref,'tag_']);
    
    
    % a historic rest of the old method
    scard_iteref{iref}.database_gpu_shifts_shrink_factor=shifts_shrink_factor;
    
    % unchanging information
    scard_iteref{iref}.database_gpu_file_particle_extension = vpr.feature_extension_data;
    
    
    % gpu identifiers
    scard_iteref{iref}.gpu_identifier_set=vpr.gpu_identifier_set;
    
    
    
    
    dynamo_write(scard_iteref{iref},files_scard_iteref{iref});
end






%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 2   Assignation of particles to GPUs
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function local_iteration_setup_gpu_assign(vpr,scard,runtimeManager);

ite   = scard.database_ite;
nref  = scard.nref;

paddingInProject = vpr.feature_data_padding;
if isnan(paddingInProject)
    disp('<iteration setup gpu> Padding of particle data names has been set arbitrarily to 5');
    disp('Probably we are using a new data container, don''t worry.');
    paddingInProject = 5;
end


assign_ref=dynamo_database_read('assign_ref',vpr,'ref',1:nref,'ite',ite);
assign_ref=cell_checkin(assign_ref);

number_gpus=length(vpr.gpu_identifier_set);


created_assignation_files = {};

currentRefs = dpkproject.pipeline.getSurvivingReferences(vpr,ite);
if isempty(currentRefs)
    error('No references to proceed. Project shoudl be complete by now.');
end



for iref=1:nref
    
    if ~ismember(iref,currentRefs);continue;end
    
    tags_in_ref=assign_ref{currentRefs == iref};
    
    
    number_tags_for_each_gpu=ceil(length(tags_in_ref)/(vpr.how_many_processors*number_gpus));
    
    disp(sprintf('Reference map #%d will be  compared to %d particles. \r  Assigning %d particles to each GPU (%d available per processor) in a fixed processor (%d available).',....
        iref,length(tags_in_ref),number_tags_for_each_gpu,number_gpus, vpr.how_many_processors));
    
    
    file_starting_reftable = dynamo_database_locate('starting_table',vpr,'ref',iref,'ite',ite,'check','disk');
    
    if isempty(file_starting_reftable)        
        error('Cannot find starting table file for ref %d ite %d',iref,ite);
    end    
    starting_reftable = dynamo_read(file_starting_reftable);
    
    chunk_counter=1;
    % vpr.how_many_processors can only be one with the current settings,
    % but we keep this structure anyway to ensure generality and
    % portability in further versions.
    for proc=0:vpr.how_many_processors-1
        
        for gpu=vpr.gpu_identifier_set;
            chunk_indices=(1:number_tags_for_each_gpu)+(chunk_counter-1)*number_tags_for_each_gpu;
            
            all_indices=1:length(tags_in_ref);
            chunk_indices_no_overflow=intersect(chunk_indices,all_indices);
            
            tags_in_gpu=tags_in_ref(chunk_indices_no_overflow);
            
            % now, GPU will always use the full particle size
            assignation_file = dynamo_database_locate('assign_gpu',vpr,'proc',proc,'ref',iref,'gpu',gpu,'ite',ite);            
            created_assignation_files{end+1} = assignation_file;            
            dynamo_tags_write(tags_in_gpu,assignation_file,paddingInProject);
            
            %% literal assignation files (if needed)
            assignation_file_particleList = dpkproject.pipeline.gpu.createParticleFileListAssignations(....
                proc,iref,gpu,ite,runtimeManager,tags_in_gpu);

            
            
            %% creates the starting table for this combination of reference, processor and gpu
            
            
            file_gpuProcRefTable = dynamo_database_locate('starting_gpuProcRefTable',....
                vpr,'proc',proc,'ref',iref,'gpu',gpu,'ite',ite);
            
            
            table_gpuProcRef = dynamo_table_grep(starting_reftable,'tags',tags_in_gpu);
            
            dynamo_write(table_gpuProcRef,file_gpuProcRefTable);
            
            
            chunk_counter=chunk_counter+1;
        end
        
    end
end

disp(sprintf('A total of %d assignation files ("assign_gpu" database items) have been created.  ',length(created_assignation_files)));
%dispc(created_assignation_files);




%
% END main function
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Resampling of data
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [folder_data_resampled,shifts_shrink_factor]=local_iteration_setup_gpu_resizing(vpr,scard)


% by default:
folder_data_resampled=vpr.folder_data;
shifts_shrink_factor=1;

ite=scard.database_ite;

o = pparse.output();
o.leading = '_iteration_setup_gpu';

facts = dynamo_data_info(vpr.folder_data,'v',0);

if isnan(facts.l)
    o.echo('Sidelength of particles is NaN. There is some problem with the formatting, check your data.');
    error('Aboting!');
end

my_round=dynamo_intertwin_ite2round(vpr,ite);

round_str=num2str(my_round);
dim=vpr.(['dim_r',round_str]);




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% checks if a resampling is necessary
%

CONVENTION_TO_ALIGN=2;
if dim==facts.l
    return;
end

nref=scard.nref;

shifts_shrink_factor=dim/facts.l;
% which particle tags do we need to have resampled?

if mod(facts.l,dim)~=0
    o.echo(' ERROR: GPU admits only resizing through integer factors (binning)');
    o.echo(' You are using the particle sidelengths:  Actually in disk: %d   Required: %d ',{facts.l,dim});
   error('Aborting'); 
end

DEBUGGING_just_get_shifts_shrink_factor = true;
if DEBUGGING_just_get_shifts_shrink_factor
    folder_data_resampled = vpr.folder_data;
    return
end


for iref=1:nref
    table_files{iref} = dynamo_database_locate('starting_table',vpr,'ref',iref,'ite',ite);
    
    if exist(table_files{iref},'file')~=2
       disp(sprintf('[dynamo: iteration_setup_gpu] NO TABLE FILE of type "starting_table" for ref %d ',iref));
       disp(sprintf('[dynamo: iteration_setup_gpu] missing file "%s"',table_files{iref}));
       error('[dynamo: iteration_setup_gpu] Aborting (missing "starting_table" file).');
    end
    
    tables{iref} = dynamo_read(table_files{iref},1);
end
    

if isempty(tables)
    error('[dynamo: iteration_setup_gpu] empty set of tables when reading "starting_table" ');
end


needed_tags=[];
for iref=1:nref
    
    if isempty(tables{iref})
        error(sprintf('[dynamo: iteration_setup_gpu] "starting_table" for ref %d had  empty content. ',iref));
    end
    
    table_reduced = dynamo_table_restrict(tables{iref},CONVENTION_TO_ALIGN,1);
    tags_ref      = table_reduced(:,1);
    
    needed_tags=unique([needed_tags;tags_ref]);
    
end


%% Ok, was a resampling already performed?
if isa(facts,'dBoxes')
    folder_data_resampled = fullfile(vpr.name_project,'rescaled_data',['data_',num2str(dim)],'.Boxes');
else
    
    folder_data_resampled = fullfile(vpr.name_project,'rescaled_data',['data_',num2str(dim)]);
end

if exist(folder_data_resampled,'dir')==7
    % which ones are already there?
    facts_scaled=dynamo_data_info(folder_data_resampled,'v',0);
    needed_tags=setdiff(needed_tags,facts_scaled.tags);
    
else
    % directory needs to be created
    
    o.echo('[setup_gpu] Creating temporary directory "%s"',folder_data_resampled);
    mkdir(folder_data_resampled);
    o.echo('[setup_gpu] Creation of temporary directory "%s" completed.',folder_data_resampled);
end

% do we need to operate anything or was it already done?



if ~isempty(needed_tags)
    
    % directory needs to be created and populated
    mess{1}=sprintf('[setup_gpu] Populating temporary directory "%s"',folder_data_resampled);
    mess{2}=sprintf('[setup_gpu] (This step will be removed in next Dynamo releases)');
    dispv(mess);
    
    for i=1:length(needed_tags);
        
        tag=needed_tags(i);
        file_particle_original_size=dynamo_database_locate('particle',vpr,'tag',tag);
        
        particle_original_size=dynamo_read(file_particle_original_size);
        % Don't worry: the suffix _template merely shows that
        % the indetended resizing if for graymaps.
        % (as binary maps are resampled differently)
        particle_rescaled=dynamo_resize_template(particle_original_size,dim);
        
        % this is the only non-database access in Dynamo. Should be
        % quickly removed.
        [dummy_path,just_file_particle_original_size,extension]=fileparts(file_particle_original_size);
        file_particle_rescaled = fullfile(folder_data_resampled,[just_file_particle_original_size,extension]);
        dynamo_write(particle_rescaled,file_particle_rescaled);
        
        
        
        % rescales the pfmask if present
        
        file_pfmask_original_size = strrep(file_particle_original_size,'particle_','pfmask_');
        
        % if the pfmask file exists, it also gets rescaled
        if exist(file_particle_rescaled,'file')==2
            pfmask_original_size = dynamo_read(file_pfmask_original_size,1);
            
            if isempty(pfmask_original_size)
                continue;
            end
            pfmask_rescaled      = dynamo_resize_template(pfmask_original_size,dim);
            
            % creates a filename along the same
            [dummy_path,just_file_pfmask_original_size,extension]=fileparts(file_pfmask_original_size);
            file_pfmask_rescaled = fullfile(folder_data_resampled,[just_file_pfmask_original_size,extension]);
            
            % writes it back
            dynamo_write(pfmask_rescaled,file_pfmask_rescaled);
        end
        
        
    end
    
end









