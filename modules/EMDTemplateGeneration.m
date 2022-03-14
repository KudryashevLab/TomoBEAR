classdef EMDTemplateGeneration < Module
    methods
        function obj = EMDTemplateGeneration(configuration)
            obj = obj@Module(configuration);
        end
        
        function obj = setUp(obj)
            obj = setUp@Module(obj);
            createStandardFolder(obj.configuration, "templates_folder");
        end
        
        function obj = process(obj)
            % TODO: error handling when file is not downloadable
            url = sprintf("http://www.ebi.ac.uk/pdbe/entry/download/EMD-%s/bundle", obj.configuration.template_emd_number);
            file_name_without_extension = "EMD-" + obj.configuration.template_emd_number;
            file_name =  file_name_without_extension + ".tar.gz";
            
            template_destination = obj.output_path + string(filesep) + file_name;
            
            obj.temporary_files(end + 1) = template_destination;
            
            output = executeCommand("wget "...
                + "-O " + template_destination...
                + " " + url, obj.log_file_id);
            
            fprintf("INFO: extracting emd structure %s...", obj.configuration.template_emd_number);
            
            %[status, message, message_id] = mkdir(output_);
            
            obj.temporary_files(end + 1) = obj.output_path + string(filesep) + file_name_without_extension;
            
            output = executeCommand("tar"...
                + " xvfz " + template_destination...
                + " -C " + obj.output_path);
            
            file_name_splitted = strsplit(file_name, ".");
            file_name_splitted_replaced = strrep(file_name_splitted, "-", "_");
            file_name_splitted_replaced_lowercased = lower(file_name_splitted_replaced);
            map_path = obj.output_path + string(filesep) + file_name_without_extension + string(filesep) + "map" + string(filesep) + file_name_splitted_replaced_lowercased{1} + ".map";
            map_path_char = char(map_path);
            
            if obj.configuration.dark_density == true
              else
                template = dread(map_path_char);
            end
            
            if obj.configuration.flip_handedness == true
                template = template(:,:,end:-1:1);
            end
            
            template_pixel_size = getPixelSizeFromHeader(map_path, obj.log_file_id);
            
            
            %for i = 1:length(obj.configuration.binning)
            binning_factor = obj.configuration.template_matching_binning; %/ obj.configuration.aligned_stack_binning;
            binning = binning_factor;
%             binning = obj.configuration.template_matching_binning * obj.configuration.aligned_stack_binning;
            % TODO: what about homogenized data
%             rescaled_pixelsize = obj.configuration.apix * binning;
%             rescaled_pixelsize = obj.configuration.greatest_apix * binning; % obj.configuration.smallest_apix 
            [rescaled_pixelsize, apix] = getApix(obj.configuration, obj.configuration.template_matching_binning);

            scaling_ratio = str2double(template_pixel_size)/(rescaled_pixelsize);
            
            
            %             tilt_geometry = obj.configuration.tilt_geometry;
            %             projections = abs(tilt_geometry(1)-tilt_geometry(2)) / tilt_geometry(3);
            %             m = projections;
            template_scaled_to_actual_data = length(template) * (1 / (apix * obj.configuration.ft_bin));
            %             if obj.configuration.use_half_template_size == true
            %                 template_scaled_to_actual_data = template_scaled_to_actual_data / 2;
            %             end
            
            
            %             D = template_scaled_to_actual_data * obj.configuration.smallest_apix; %str2num(template_pixel_size)
            %             dx = (pi*D)/m;
            
            %             max_tilt_angle = (max(tilt_geometry));
            %
            %             exz = sqrt((max_tilt_angle+sin(max_tilt_angle)*cos(max_tilt_angle))/(max_tilt_angle-sin(max_tilt_angle)*cos(max_tilt_angle)));
            %
            %             dz = dx*exz;
            dz = obj.configuration.template_bandpass_cut_off_resolution_in_angstrom;
            fsc = 1:template_scaled_to_actual_data;
            
            obj.dynamic_configuration.fp = ceil((2 * apix * obj.configuration.ft_bin)*length(fsc)/dz);
            
            obj.dynamic_configuration.angstrom_template = (2*apix * obj.configuration.ft_bin)*length(fsc)/obj.dynamic_configuration.fp;
            
            
            if obj.configuration.use_bandpassed_template == true
                band_passed_template = dbandpass(template, [obj.configuration.template_bandpass_cut_on_fourier_pixel obj.dynamic_configuration.fp obj.configuration.template_bandpass_smoothing_pixels]);
            else
                band_passed_template = template;
            end
            mask = dbandpass(-template, obj.configuration.mask_bandpass);
            
            
            % TODO: need better criterion or check values
            %
            %             mask_frequency_cut_off = scaling_ratio .* obj.configuration.mask_cut_off;
            %             % NOTE: formerly 0.15
            %             template_frequency_cut_off = scaling_ratio .* obj.configuration.template_cut_off;
            %             template_band_pass_filter = obj.BH_bandpass3d(size(template), 0, 0, 1/template_frequency_cut_off, "GPU", 1);
            %             band_passed_template = gather(real(ifftn(fftn(template) .* template_band_pass_filter)));
            
            available_mask = dir(obj.output_path + string(filesep) + "**" + string(filesep) + "*msk*.map");
            
            
            if obj.configuration.type == "emClarity"
                %                     try
                %TODO: rescale to next even integer
                rescaled_template = gather(obj.rescale_volume(template, "", scaling_ratio, "GPU"));
                rescaled_template = makeEvenVolumeDimensions(rescaled_template);
                
                rescaled_band_passed_template = gather(obj.rescale_volume(band_passed_template, "", scaling_ratio, "GPU"));
                rescaled_band_passed_template = makeEvenVolumeDimensions(rescaled_band_passed_template);
                
                template_band_pass_filter = obj.BH_bandpass3d(size(rescaled_template), 0, 0, 1/template_frequency_cut_off, "GPU", 1);
                mask_band_pass_filter = obj.BH_bandpass3d(size(rescaled_template), 0, 0, 1/mask_frequency_cut_off, "GPU", 1);
                mask = real(ifftn(fftn(rescaled_template) .* mask_band_pass_filter));
                try
                    mask_binarized = gather(imbinarize(mask));
                catch
                    mask_binarized = imbinarize(gather(mask));
                end
                mask_binarized_smoothed = gather(real(ifftn(fftn(mask_binarized) .* template_band_pass_filter)));
                mask_binarized_smoothed_cleaned = mask_binarized_smoothed .* mask_binarized;
                
                
                
                %rescaled_mask_binarized = rescale_volume(mask_binarized, "", scaling_ratio, "GPU");
                %rescaled_mask_binarized_smoothed_cleaned = rescale_volume(mask_binarized_smoothed_cleaned, "", scaling_ratio, "GPU");
                %                     catch
                %                         rescaled_template = obj.rescale_volume(template, "", scaling_ratio, "CPU");
                %                         rescaled_band_passed_template = obj.rescale_volume(band_passed_template, "", scaling_ratio, "CPU");
                %
                %                         template_band_pass_filter = obj.BH_bandpass3d(size(rescaled_template), 0, 0, 1/template_frequency_cut_off, "GPU", 1);
                %                         mask_band_pass_filter = obj.BH_bandpass3d(size(rescaled_template), 0, 0, 1/mask_frequency_cut_off, "GPU", 1);
                %                         mask = gather(real(ifftn(fftn(rescaled_template) .* mask_band_pass_filter)));
                %                         mask_binarized = imbinarize(mask);
                %                         mask_binarized_smoothed = gather(real(ifftn(fftn(mask_binarized) .* template_band_pass_filter)));
                %                         mask_binarized_smoothed_cleaned = mask_binarized_smoothed .* mask_binarized;
                %
                %
                %                         %rescaled_mask_binarized = rescale_volume(single(mask_binarized), "", scaling_ratio, "CPU");
                %                         %rescaled_mask_binarized_smoothed_cleaned = rescale_volume(mask_binarized_smoothed_cleaned, "", scaling_ratio, "CPU");
                %                     end
            elseif obj.configuration.type == "dynamo"
                rescaled_template = dynamo_rescale(template, template_pixel_size, rescaled_pixelsize);
                rescaled_band_passed_template = dynamo_rescale(band_passed_template, template_pixel_size, rescaled_pixelsize);
                rescaled_template = makeEvenVolumeDimensions(rescaled_template);
                rescaled_band_passed_template = makeEvenVolumeDimensions(rescaled_band_passed_template);

                %                 template_band_pass_filter = obj.BH_bandpass3d(size(rescaled_template), 0, 0, 1/template_frequency_cut_off, "GPU", 1);
                %                 mask_band_pass_filter = obj.BH_bandpass3d(size(rescaled_template), 0, 0, 1/mask_frequency_cut_off, "GPU", 1);
                %                 mask = real(ifftn(fftn(rescaled_template) .* mask_band_pass_filter));
                
                mask_binarized = gather(imbinarize(mask));
                mask_binarized_morphed = zeros(size(mask_binarized));
                for i = 1:length(mask_binarized)
                    mask_binarized_morphed(:,:,i) = bwmorph(mask_binarized(:,:,i),"thicken", ceil(size(mask_binarized,3)*obj.configuration.ratio_mask_pixels_based_on_unbinned_pixels));
                end
                for i = 1:length(mask_binarized)
                    mask_binarized_morphed(:,i,:) = bwmorph(reshape(mask_binarized_morphed(:,i,:), size(mask_binarized_morphed(:,:,i), [1 2])) , "thicken", ceil(size(mask_binarized,2) * obj.configuration.ratio_mask_pixels_based_on_unbinned_pixels));
                end
                mask_binarized = imbinarize(mask_binarized_morphed);
               % mask = dbandpass(mask_binarized_morphed, obj.configuration.mask_bandpass);

                %                 mask_binarized_smoothed = gather(real(ifftn(fftn(mask_binarized) .* template_band_pass_filter)));
                %                 mask_binarized_smoothed_cleaned = mask_binarized_smoothed .* mask_binarized;
%                 mask_binarized_smoothed_cleaned = mask.*mask_binarized;
                mask_binarized_smoothed_cleaned = dbandpass(mask_binarized_morphed, obj.configuration.mask_bandpass);
                mask_binarized = dynamo_rescale(double(mask_binarized), template_pixel_size, rescaled_pixelsize);
                mask_binarized_smoothed_cleaned = dynamo_rescale(mask_binarized_smoothed_cleaned, template_pixel_size, rescaled_pixelsize);
                mask_binarized = makeEvenVolumeDimensions(mask_binarized,0);
                mask_binarized_smoothed_cleaned = makeEvenVolumeDimensions(mask_binarized_smoothed_cleaned,0);

                
                %rescaled_mask_binarized = dynamo_rescale(mask_binarized, template_pixel_size, configuration.apix * configuration.binning(i));
                %rescaled_mask_binarized_smoothed_cleaned = dynamo_rescale(mask_binarized_smoothed_cleaned, template_pixel_size, configuration.apix * configuration.binning(i));
            else
                error("ERROR: method not implemented!");
            end
            
            
            template_destination = char(obj.output_path + string(filesep) + "template_bin_" + num2str(binning) + ".mrc");
            template_destination_band_passed = char(obj.output_path + string(filesep) + "template_band_passed_bin_" + num2str(binning) + ".mrc");
            
            
            dwrite(rescaled_template, template_destination);
            dwrite(rescaled_band_passed_template, template_destination_band_passed);
            
            mask_link_destination = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder...
                + string(filesep) + obj.configuration.templates_folder + string(filesep) + "mask_bin_" + num2str(binning) + ".mrc";
            template_link_destination = obj.configuration.processing_path + string(filesep) + obj.configuration.output_folder...
                + string(filesep) + obj.configuration.templates_folder + string(filesep) + "template_bin_" + num2str(binning) + ".mrc";
            
            %mask_destination = char(obj.output_path + string(filesep) + "mask_bin_" + num2str(configuration.binning(i)) + ".mrc");
            mask_binarized_destination = char(obj.output_path + string(filesep) + "mask_binarized_bin_" + num2str(binning) + ".mrc");
            mask_smoothed_destination = char(obj.output_path + string(filesep) + "mask_smoothed_bin_" + num2str(binning) + ".mrc");
            if obj.configuration.use_bandpassed_template == true
                createSymbolicLink(template_destination_band_passed, template_link_destination, obj.log_file_id);
            else
                createSymbolicLink(template_destination, template_link_destination, obj.log_file_id);
            end
            
            
            if ~isempty(available_mask)
                mask = dread(char(available_mask.folder + string(filesep) + available_mask.name));                
                rescaled_mask = obj.rescale_volume(mask, "", scaling_ratio, "CPU");
                rescaled_mask = makeEvenVolumeDimensions(rescaled_mask);
                
                bandpassed_mask = dbandpass(mask, obj.configuration.mask_bandpass);
                
                rescaled_bandpasse_mask = obj.rescale_volume(bandpassed_mask, "", scaling_ratio, "CPU");
                rescaled_bandpasse_mask = makeEvenVolumeDimensions(rescaled_bandpasse_mask);
                %mask = gather(real(ifftn(fftn(rescaled_template) .* mask_band_pass_filter)));
                dwrite(rescaled_bandpasse_mask, mask_smoothed_destination)
                dwrite(rescaled_mask, mask_binarized_destination)

                createSymbolicLink(available_mask.folder + string(filesep) + "bandpassed_"  + available_mask.name + ".mrc", mask_link_destination, obj.log_file_id);
                if obj.configuration.use_smoothed_mask == true
                    createSymbolicLink(mask_smoothed_destination, mask_link_destination, obj.log_file_id);
                else
                    createSymbolicLink(mask_binarized_destination, mask_link_destination, obj.log_file_id);
                end
            else
                
                dwrite(mask_binarized, mask_binarized_destination);
                dwrite(mask_binarized_smoothed_cleaned, mask_smoothed_destination);
                if obj.configuration.use_smoothed_mask == true
                    createSymbolicLink(mask_smoothed_destination, mask_link_destination, obj.log_file_id);
                else
                    createSymbolicLink(mask_binarized_destination, mask_link_destination, obj.log_file_id);
                end
            end
            %end
        end
        
        % TODO: review functions from ben himes
        function rescaled_volume = rescale_volume(obj, inputVol, nameOUT, MAG, METHOD)
            %UNTITLED Summary of this function goes here
            %   Detailed explanation goes here
            
            if (isnumeric(MAG))
                mag = MAG;
            else
                mag = str2num(MAG);
            end
            
            pixelSize = 1.0;
            if isa(inputVol, 'cell')
                nVols = length(inputVol);
                outPutArray = false;
                writeOut = false;
            elseif isnumeric(inputVol)
                nVols = 1;
                outPutArray = true;
                inputVol = {inputVol};
                writeOut = false;
            elseif ischar(inputVol)
                [imgPath, imgName, imgExt] = fileparts(inputVol);
                if isempty(imgPath)
                    imgPath = '.';
                end
                % Read in the image
                nVols = 1;
                mrcImage = MRCImage(inputVol,0);
                header = getHeader(mrcImage);
                pixelSizeX = header.cellDimensionX / header.nX;
                pixelSizeY = header.cellDimensionY / header.nY;
                if pixelSizeX ~= pixelSizeY
                    fprintf('\npixel size in X (%2.2f), Y (%2.2f) inconsistent, leaving unset\n',pixelSizeX,pixelSizeY);
                else
                    pixelSize = pixelSizeX;
                end
                inputVol = {getVolume(mrcImage)};
                writeOut = true;
                outPutArray = false;
                
            end
            rescaled_volume = cell(nVols,1);
            
            % Assuming all images are the same size
            sizeVol = size(inputVol{1});
            
            if length(sizeVol) ~= 3
                error('rescale only set to work on 3d volumes');
            end
            % % % if mag > 1
            % % %   sizeOut = round(sizeVol./mag);
            % % % else
            % % %   sizeOut = sizeVol;
            % % % end
            sizeOut = round(sizeVol.*mag);
            
            % Bandlimit first and clear mask to save memory
            freqCutoff = mag.*0.475;
            bandPass = obj.BH_bandpass3d(sizeVol,0,0,1/freqCutoff,METHOD,1);
            
            for iVol = 1:nVols
                inputVol{iVol} = real(ifftn(fftn(inputVol{iVol}).*bandPass));
            end
            
            clear bandPass
            
            [~,~,~,x,y,z] = obj.BH_multi_gridCoordinates(sizeVol,'Cartesian',METHOD,...
                {'single',[1,0,0;0,1,0;0,0,1],...
                [0,0,0]','forward',1,mag},0,1,0);
            
            [X,Y,Z,~,~,~] = obj.BH_multi_gridCoordinates(sizeOut,'Cartesian',METHOD,...
                {'single',[1,0,0;0,1,0;0,0,1],...
                [0,0,0]','forward',1,mag},0,1,0);
            
            
            
            for iVol = 1:nVols
                if strcmp(METHOD,'GPU')
                    rescaled_volume{iVol} = interpn(x,y,z, inputVol{iVol}, X, Y, Z, 'linear',0);
                else
                    rescaled_volume{iVol} = interpn(x,y,z, inputVol{iVol}, X, Y, Z, 'spline',0);
                    rescaled_volume{iVol}(isnan(rescaled_volume{iVol})) = 0;
                end
                clear inputVol{iVol}
            end
            
            clear x y z X Y Z
            
            if ( outPutArray )
                rescaled_volume = rescaled_volume{1};
            elseif( writeOut )
                SAVE_IMG(MRCImage(gather(single(rescaled_volume{1}))), nameOUT,pixelSize./mag);
            end
            
        end
        
        function [ Gc1,Gc2,Gc3,g1,g2,g3 ] = BH_multi_gridCoordinates(obj, SIZE, SYSTEM, METHOD, ...
                TRANSFORMATION, ...
                flgFreqSpace, ...
                flgShiftOrigin, flgRad, ...
                varargin)
            %Return grid vectors in R3 for various coordinate systems.
            %   Create grid vectors of dimension SIZE, that are either Cartesian,
            %   Cylindrical, or Spherical. Optionally only return a matrix with radial
            %   values. Grids are centered with the origin at ceil(N+1/2).
            if strcmpi(METHOD,'GPU')
                SIZE = gpuArray(single(SIZE));
            else
                SIZE = single(SIZE);
            end
            
            % Option to use pre-created vectors which is surprisingly expensive to
            % create.
            makeVectors = 1;
            if nargin == 9
                makeVectors = 0;
                x1 = varargin{1}{1};
                y1 = varargin{1}{2};
                z1 = varargin{1}{3};
            end
            
            if numel(SIZE) == 3
                sX = SIZE(1) ; sY = SIZE(2) ; sZ = SIZE(3);
                
                flg3D = 1;
            elseif numel(SIZE) == 2
                sX = SIZE(1) ; sY = SIZE(2) ;
                if strcmpi(METHOD,'GPU'); sZ = gpuArray(single(1)); else sZ = single(1);end
                flg3D = 0;
            else
                error('Only 2D or 3D grid vectors are supported.');
            end
            
            % flgShiftOrigin handles whether to place the origin at the center of the image
            % (TRUE) or not (FALSE; use for FFTs) and optionally to handle offsets due to
            % different conventions in other software. E.g. IMOD defines the center as NX/2
            % which creates a different value for even/odd images.
            if length(flgShiftOrigin) == 4
                % the origin in IMODs case for an even image is -0.5 relative to mine.
                % Switching to force odd size - 20171201
                conventionShift = [0,0,0];
                %   conventionShift = flgShiftOrigin(2:4) .* (1-mod([sX,sY,sZ],2));
                flgShiftOrigin = flgShiftOrigin(1);
            else
                conventionShift = [0,0,0];
            end
            flgTrans = 1;
            flgGridVectors = 0;
            flgSymmetry = 0;
            flgSequential = 0;
            
            symInc = 0;
            symIDX = 0;
            
            flgMask = 0;
            if iscell(TRANSFORMATION)
                
                switch TRANSFORMATION{1}
                    
                    case 'none'
                        flgTrans = 0;
                        R = [1,0,0;0,1,0;0,0,1];
                        dXYZ = [0,0,0]';
                        DIR = 'forwardVector';
                        MAG = {1};
                        % The majority of function calls that are not in a resample/rescale
                        % program call this case, and don't expect a cell output.
                        
                        
                    case 'gridVectors'
                        flgGridVectors = 1;
                        R = [1,0,0;0,1,0;0,0,1];
                        dXYZ = TRANSFORMATION{3};
                        DIR = 'forwardVector';
                        MAG = {TRANSFORMATION{6}};
                        
                    case 'single'
                        if numel(TRANSFORMATION{2}) == 9
                            R = reshape(TRANSFORMATION{2},3,3);
                        else
                            R = reshape(TRANSFORMATION{2},2,2);
                        end
                        
                        dXYZ = TRANSFORMATION{3};
                        if length(dXYZ) == 2
                            dXYZ = [dXYZ;0];
                        end
                        DIR = TRANSFORMATION{4};
                        if (TRANSFORMATION{5} > 1)
                            flgSymmetry = TRANSFORMATION{5};
                            symInc = 360 / flgSymmetry;
                            symIDX = 0:flgSymmetry-1;
                            Gc1 = cell(flgSymmetry,1);
                            Gc2 = cell(flgSymmetry,1);
                            Gc3 = cell(flgSymmetry,1);
                        else
                            symIDX = 1;
                            symInc = 0;
                        end
                        
                        if strcmpi(DIR, 'inv') || strcmpi(DIR,'forwardVector')
                            MAG = {TRANSFORMATION{6}};
                        else
                            MAG = {1./TRANSFORMATION{6}}; % faster to just do A(I) but left as {{}} for clarity
                        end
                        
                        if length(TRANSFORMATION) == 7
                            if islogical(TRANSFORMATION{7})
                                binaryVol = TRANSFORMATION{7};
                                flgMask = 1;
                            end
                        end
                        
                        
                        
                        
                    case 'sequential'
                        flgSequential = 1;
                        
                        if ( size(TRANSFORMATION,1) > 2 )
                            error('Initial only implement up to 2 sequential transformations.\n')
                        elseif (TRANSFORMATION{1,5} ~= 1)
                            error('no Symmetry operations on sequential transformations.\n')
                        elseif ~strcmpi(TRANSFORMATION{1,4}, 'forward')
                            error('only forward transformations supported for sequential.\n')
                        else
                            nTrans = 2;
                        end
                        
                        for iTrans = 1:nTrans
                            R_seq{iTrans} = reshape(TRANSFORMATION{iTrans,2},3,3);
                            
                            dXYZ_seq{iTrans} = TRANSFORMATION{iTrans,3};
                            
                            
                            % Convention is only forward so np need to consider flipping
                            MAG_seq{iTrans} = TRANSFORMATION{iTrans,6};
                            
                        end
                        % For now assuming no symmetry operation on sequential transformations
                        flgSymmetry = TRANSFORMATION{1,5};
                        DIR = TRANSFORMATION{1,4};
                        
                        symInc = 360 / flgSymmetry;
                        symIDX = 0:flgSymmetry-1;
                        Gc1 = {}; Gc2 = {}; Gc3 ={};
                        
                        
                        
                    otherwise
                        error(['TRANSFORMATION must be a cell,',...
                            '(none,gridVectors,single,sequential),',...
                            'Rotmat, dXYZ, forward|inv, symmetry\n']);
                end
            end
            
            
            if ( makeVectors )
                if strcmpi(METHOD, 'GPU')
                    % sX = gpuArray(sX) ; sY = gpuArray(sY) ; sZ = gpuArray(sZ);
                    if flgShiftOrigin == 1
                        %      x1 = [-1*floor((sX)/2):0,1:floor((sX-1)/2)];
                        %      y1 = [-1*floor((sY)/2):0,1:floor((sY-1)/2)];
                        x1 = [-1*floor((sX)/2):floor((sX-1)/2)];
                        y1 = [-1*floor((sY)/2):floor((sY-1)/2)];
                        if (flg3D); z1 = [-1*floor((sZ)/2):floor((sZ-1)/2)]; end
                        
                        %      if (flg3D); z1 = [-1*floor((sZ)/2):0,1:floor((sZ-1)/2)]; end
                    elseif flgShiftOrigin == -1
                        x1 = [1:sX];
                        y1 = [1:sY];
                        if (flg3D); z1 = [1:sZ]; end
                    elseif flgShiftOrigin == -2
                        x1 = fftshift([1:sX]);
                        y1 = fftshift([1:sY]);
                        if (flg3D); z1 = fftshift([1:sZ]); end
                    else
                        x1 = [0:floor(sX/2),-1*floor((sX-1)/2):-1];
                        y1 = [0:floor(sY/2),-1*floor((sY-1)/2):-1];
                        if (flg3D); z1 = [0:floor(sZ/2),-1*floor((sZ-1)/2):-1]; end
                    end
                elseif strcmpi(METHOD, 'cpu')
                    if flgShiftOrigin == 1
                        x1 = [-1*floor((sX)/2):0,1:floor((sX-1)/2)];
                        y1 = [-1*floor((sY)/2):0,1:floor((sY-1)/2)];
                        if (flg3D); z1 = [-1*floor((sZ)/2):0,1:floor((sZ-1)/2)]; end
                    elseif flgShiftOrigin == -1
                        x1 = [1:sX];
                        y1 = [1:sY];
                        if (flg3D); z1 = [1:sZ]; end
                    elseif flgShiftOrigin == -2
                        x1 = fftshift([1:sX]);
                        y1 = fftshift([1:sY]);
                        if (flg3D); z1 = fftshift([1:sZ]); end
                    else
                        x1 = [0:floor(sX/2),-1*floor((sX-1)/2):-1];
                        y1 = [0:floor(sY/2),-1*floor((sY-1)/2):-1];
                        if (flg3D); z1 = [0:floor(sZ/2),-1*floor((sZ-1)/2):-1]; end
                    end
                else
                    error('METHOD should be cpu or GPU')
                end
            end
            
            % Make any needed shifts for convention
            x1 = x1 - conventionShift(1);
            y1 = y1 - conventionShift(2);
            if (flg3D); z1 = z1 - conventionShift(3); end
            
            if strcmpi(DIR, 'inv') || strcmpi(DIR, 'forwardVector')
                x1 = x1 - dXYZ(1);
                y1 = y1 - dXYZ(2);
                if (flg3D); z1 = z1 - dXYZ(3); end
                
                shiftDir = -1;
            else
                shiftDir = 1;
            end
            
            if (flgFreqSpace)
                x1 = x1 ./ sX;
                y1 = y1 ./ sY;
                if (flg3D); z1 = z1 ./ sZ; end
            end
            
            
            if ~(flg3D)
                z1 = 0;
            end
            % save grid vectors prior to any transformations
            g1 = x1; g2 = y1; g3 = z1;
            
            if (flgGridVectors)
                G1 = ''; G2 = ''; G3 = '';
                return
            end
            
            % Rescale the vectors prior to making gridVectors
            if (flgSequential)
                x1 = x1.*MAG_seq{1};
                y1 = y1.*MAG_seq{1};
                z1 = z1.*MAG_seq{1};
            else
                x1 = x1.*MAG{1};
                y1 = y1.*MAG{1};
                z1 = z1.*MAG{1};
            end
            
            % No matter the case, the cartesian grids are needed
            [X,Y,Z] = ndgrid(x1,y1,z1);
            
            
            % Optionally evaluate only a smaller masked region
            if (flgMask)
                X = X(binaryVol);
                Y = Y(binaryVol);
                Z = Z(binaryVol);
            end
            
            % for non-sequential transformations this only loops once.
            for iTrans = 1:1+(flgSequential)
                
                if (flgSequential)
                    rAsym = R_seq{iTrans};
                    if (iTrans == 1)
                        dXyzAsym = 0;
                        % Instead of shifting then shifting back, just note the original shift
                    else
                        % adding the R2' because the first term doesn't need to be multiplied by
                        % R2 (in the first action under symmetry loop) but making a change here
                        % which involves extra multiplications is okay, since this function is
                        % used much less than 'single' style resampling.
                        dXyzAsym = ( R_seq{iTrans}'*R_seq{iTrans-1} * ...
                            dXYZ_seq{iTrans-1}.*MAG_seq{iTrans-1} + ...
                            R_seq{iTrans-1} * dXYZ_seq{iTrans}.*MAG_seq{iTrans} );
                        
                        X = Gc1{1}.*MAG_seq{iTrans};
                        Y = Gc2{1}.*MAG_seq{iTrans};
                        Z = Gc3{1}.*MAG_seq{iTrans};
                    end
                else
                    rAsym = R;
                    % Note that if symmetric, dXYZ changes each loop after this point
                    dXyzAsym = dXYZ.*MAG{1};
                end
                
                for iSym = symIDX
                    
                    % Only in plane symmetries considered anywhere so inv|forward shouldn't
                    % matter.
                    
                    R = rAsym * obj.BH_defineMatrix([iSym.*symInc,0,0],'Bah','inv');
                    
                    % Any forward transformations of the grids
                    if (flgTrans)
                        dXYZ = shiftDir .* R*dXyzAsym;
                        
                        Xnew = X.*R(1) + Y.*R(4) + Z.*R(7) - dXYZ(1);
                        Ynew = X.*R(2) + Y.*R(5) + Z.*R(8) - dXYZ(2);
                        if (flg3D)
                            Znew = X.*R(3) + Y.*R(6) + Z.*R(9) - dXYZ(3);
                        else
                            Znew = 0;
                        end
                    else
                        Xnew = X; Ynew = Y ; Znew = Z;
                    end
                    
                    % Only return the radial grid if requested
                    if (flgRad)
                        G1 = sqrt(Xnew.^2 + Ynew.^2 + Znew.^2);
                        G2 = '';
                        G3 = '';
                        
                    else
                        switch SYSTEM
                            case 'Cartesian'
                                G1 = Xnew; G2 = Ynew; G3 = Znew;
                            case 'Spherical'
                                G1 = sqrt(Xnew.^2 + Ynew.^2 + Znew.^2);
                                G2 = atan2(Ynew,Xnew);
                                % set from [-pi,pi] --> [0,2pi]
                                G2(G2 < 0) = G2(G2 < 0) + 2.*pi;
                                % [0,pi]
                                G3 = acos(Z./G1);
                                
                            case 'Cylindrical'
                                
                                G1 = sqrt(Xnew.^2 + Ynew.^2);
                                G2 = atan2(Ynew,Xnew);
                                % set from [-pi,pi] --> [0,2pi]
                                G2(G2 < 0) = G2(G2 < 0) + 2.*pi;
                                G3 = Znew;
                                
                            otherwise
                                error('SYSTEM must be Cartesian, Spherical, Cylindrical')
                        end
                    end
                    % Only use as cell if symmetry is requested
                    if (flgSymmetry)
                        %
                        
                        Gc1{iSym+1} = G1;
                        Gc2{iSym+1} = G2;
                        Gc3{iSym+1} = G3;
                    else
                        Gc1 = G1 ; clear G1
                        Gc2 = G2 ; clear G2
                        Gc3 = G3 ; clear G3
                    end
                end % loop over symmetric transformations
            end % loop over sequential transformations
            
            
            
            clear X Y Z  Xnew Ynew Znew x1 y1 z1
            
        end
        
        function [ BANDPASS ] = BH_bandpass3d(obj, SIZE, HIGH_THRESH, HIGH_CUT, LOW_CUT, ...
                METHOD, PIXEL_SIZE )
            %Create a bandpass filter, to apply to fft of real space 3d images.
            %
            %   Input variables:
            
            %   SIZE = size of the image filter is to be applied to : vector, float
            %
            %   HIGH_THRESH = Percent attenuation of low frequency : float
            %
            %   HIGH_CUT  = Spatial frequency high-pass back to 100% (A^-1) : float
            %
            %   LOW_CUT= Spatial frequency low-pass starts to roll off :  float
            %
            %   METHOD = 'GPU' case specific, create mask on GPU, otherwise on CPU
            %
            %   PIXEL_SIZE = Sampling frequency : Angstrom/Pixel
            %
            %
            %   Output variables:
            %
            %   BANDPASS  = 3d MRC image file, single precision float.
            %
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %
            %   Goals & Limitations:
            %
            %   Creates a bandpass filter, that falls off smoothly enough to avoid
            %   artifacts, while also restricting information to the expected ranges.
            %   This is accomplished by oversampling the image to be filtered, so that
            %   the fall off can be over a sufficient number of pixels, while still
            %   happening over a small range of frequency.
            %
            %   Because this is frequency space, the fall off depends on the resolution
            %   where it begins. For sampling of 3A/pixel with a cutoff starting at
            %   20A^-1 the spatial frequency drops to ~ 17.3 over six pixels if the
            %   frequency rectangle is 256 pixel sq. For a cutoff starting at 10A the
            %   drop over 6 pixels is only to ~9.3
            %
            %   For the monolayer work, the largest dimension is ~140 pixels, s.t. 256
            %   provides a substantial padding for cross-correlation, and also a
            %   reasonably tight window for filtering. The memory requirements are ~
            %   67/134 mb for single/double precision, compared to another order of
            %   magnitude for 512.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %
            %   TODO:
            %     -test with gpu flag
            %
            %
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            
            % The following will adjust the apodization window, and is not intended for
            % regular users to adjust. The value of 2.0 makes for a nice (soft) fall
            % off over ~ 7 pixels. Larger value results in a steeper cutoff.
            % Corresponds to the standard deviation in the gaussian roll.
            if isnumeric(PIXEL_SIZE)
                [bSize, highRoll, lowRoll, highCut, lowCut] = obj.calc_frequencies( ...
                    SIZE, HIGH_THRESH, HIGH_CUT, LOW_CUT, PIXEL_SIZE );
            else
                bSize = SIZE;
                if strcmp(PIXEL_SIZE,'nyquistHigh')
                    highCut = 7/min(bSize(bSize>1));
                    highThresh = 1e-6;
                    highRoll = sqrt((-1.*highCut.^2)./(2.*log(highThresh)));
                else
                    highCut = 0; highThresh = 0; highRoll = 0;
                end
                lowRoll = 1.5 .* (1.0./min(bSize(bSize>1)));
                lowCut = 0.485+LOW_CUT;
            end
            gaussian = @(x,m,s) exp( -1.*(x-m).^2 ./ (2.*s.^2) );
            
            
            
            % initialize window of appropriate size
            if strcmp(METHOD, 'GPU')
                mWindow(bSize(1),bSize(2),bSize(3)) = gpuArray(single(0));
            else
                mWindow(bSize(1),bSize(2),bSize(3)) = single(0);
            end
            mWindow = mWindow + 1;
            
            %%%% This is ~ 120x faster than = gpuArray(ones(bSize, 'single'));
            % initialize nd grids of appropriate size
            
            
            [ radius,~,~,~,~,~] = obj.BH_multi_gridCoordinates( bSize, 'Cartesian', METHOD, ...
                {'single',...
                [1,0,0;0,1,0;0,0,1],...
                [0,0,0]','forward',1,1}, ...
                1, 0, 1 );
            
            
            % Calc lowpass filter
            mWindow = ...
                ( (radius < lowCut) .* mWindow + ...
                (radius >= lowCut) .* gaussian(radius, lowCut, lowRoll) );
            
            % Breaks Hermitian symmetry
            % % % Don't randomize the high-pass since the signal it modulates is very
            % % % strong.
            % % mWindow = BH_multi_randomizeTaper(mWindow);
            % Add in high pass if required
            
            if highCut ~= 0
                mWindow = (radius <= highCut) .* gaussian(radius, highCut, highRoll) + ...
                    (radius > highCut) .* mWindow;
            end
            
            %mWindow((mWindow<= 10^-8)) = 0;
            BANDPASS = mWindow;
            clearvars -except BANDPASS
            
        end % end of BH_mask3d function.
        
        
        function [bSize, highRoll, lowRoll, highCut, lowCut] = calc_frequencies(obj,...
                SIZE, HIGH_THRESH, HIGH_CUT, LOW_CUT, PIXEL_SIZE )
            
            bSize = SIZE;
            
            % Check that the value makes sense.
            if ( 0 > HIGH_THRESH || HIGH_THRESH >= 1)
                error('HIGH_THRESH must be between 0 and 1, not %f', HIGH_THRESH)
            end
            
            
            
            % Translate boundries from A^-1 to cycles/pixel. A value of zero means no
            % high pass filter.
            if HIGH_CUT ~= 0
                highCut = PIXEL_SIZE ./ HIGH_CUT;
            else
                highCut = 0;
            end
            lowCut  = PIXEL_SIZE ./ LOW_CUT;
            
            % fixed lowpass roll off, cycles/pix depends on dimension of image
            % if lowCut is negative, indicates a "SIRT like" lowpass and filter rolls
            % from 1 at abs(lowCut) to 10^-8 at 20A
            
            if (lowCut > 0)
                if (bSize(3) == 1)
                    lowRoll = 2.0 .* (1.0./min(bSize(1:2)));
                else
                    lowRoll = 2.0 .* (1.0./min(bSize));
                end
            else
                lowCut = abs(lowCut);
                lowEND = 0.5;%PIXEL_SIZE ./ 20;
                lowRoll = sqrt((-1.*(lowEND-lowCut).^2)./(2.*log(10^-3)));
            end
            
            % calc the highpass roll off
            if HIGH_CUT ~= 0
                highRoll = sqrt((-1.*highCut.^2)./(2.*log(HIGH_THRESH)));
            else
                highRoll = 0;
            end
            
            
            
        end % end of calc_frequencies function.
        
        function [ ROTATION_MATRIX ] = BH_defineMatrix(obj, ANGLES, CONVENTION, DIRECTION)
            %Create a rotation matrix.
            %
            %   Input variables:
            %
            %   ANGLES = [ first, second, third ] euler angles
            %
            %   CONVENTION = 'Protomo', 'Imod', 'Spider'
            %     Protomo: ZXZ, passive, extrinsic
            %     Imod   : ZYX, active,  intrinsic
            %     Spider : ZYZ, active, extrinsic
            %     Bah    : ZXZ, active,  extrinsic
            %
            %       For the time being, I am only updating Bah, and will revisit the other
            %       conventions as time permits.
            %
            %   DIRECTION = forward : rotation from microscope frame to particle frame.
            %               inverse : rotation from particle frame to microscope frame.
            %
            %   Output variables:
            %
            %   ROTATION_MATRIX = 3d rotation matrix
            %
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %
            %   Goals & Restrictions
            %
            %   The individual rotation matrices defined below (cosine matrices) define an
            %   active right handed transformation, that is a vector is rotated about the
            %   given axis by the angle specified.
            %
            %   These are general, but in the scope of the BH_subTomo programs, they are
            %   generally applied to an ndgrid which is transformed and used as the query to
            %   an interpolation.
            %
            %   Regardless of how they are used, the angles are interpreted to reflect an
            %   active, intrinsic transformation on a particle, and the convention and
            %   direction are taken into account in order for this to work.
            %
            %	A good test is to create wedge masks of varying orientation because these
            %	rely on this function for resampling. An aysmmetric wedge is more clear.
            % 	e.g. [-50,70,0,90,0] [-50,70,60,90,0] [-50,70,0,90,60] [-50,70,90,90,-90]
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %
            %   TODO
            %     - update Protomo, Spider, Imod conversions
            %
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            if isnumeric(ANGLES(1))
                % Convert from degrees to radians.
                angles = ANGLES.*(pi./180);
            else
                % Supply random angles
                [randXYZ] = rand(1,3)-0.5;
                % Normalize to unit sphere;
                randXYZ = randXYZ ./ sqrt(sum(randXYZ.^2,2));
                angles  = [atan2(randXYZ(2),randXYZ(1)), ...
                    acos(randXYZ(3)), ...
                    (2.*pi.*(rand(1) - 0.5))]; % between -pi/pi
                
                % Make sure to override conventions for consistency.
                CONVENTION = 'Bah';
                DIRECTION =  'inv';
            end
            
            %%%%%%%%%%%%%%%%%  Angle Definitions  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Creating the anonymous functions more than doubles the run time without.
            % Using them also adds more time due to ~ 2x the trig calls.
            % Leaving them here for a reference to the matrices used.
            % Rx = @(t)[     1      0       0 ;...
            %            0  cos(t)  -sin(t);...
            %            0  sin(t)  cos(t) ];
            %
            % Ry = @(t)[ cos(t)     0   sin(t);...
            %            0      1        0;...
            %           -sin(t)     0   cos(t) ];
            %
            % Rz = @(t)[ cos(t)  -sin(t)      0;...
            %           sin(t)  cos(t)      0;...
            %             0       0      1 ];
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            if strcmpi(DIRECTION, 'forward') || strcmpi(DIRECTION, 'invVector')
                angles =  -1.*angles;
            elseif strcmpi(DIRECTION, 'inv') || strcmpi(DIRECTION, 'forwardVector')
                % For interpolation the vectors are applied to a grid, so the sense must
                % be inverted to make the final transformation active.
                
                
                % In order to rotate the particle from a position defined by the input
                % angles, back to the proper reference frame, the sense is already
                % inverted, and just the order must be inverted.
                %
                % Think of this as taking an average in the proper frame, applying a given
                % rotation with 'forward', then this undoes that action.
                %
                % IMPORTANT NOTE: because the order is flipped, successive rotations by
                % multiple matrices must be right multplied for inverse operations. eg:
                % R1(e1,e2,e3) & R2(e4,e5,e6) then Rtot = R1 * R2 = e1*e2*e3*e4*e5*e6*Mat
                angles = flip(angles);
                %   angles = [angles(3), angles(2), angles(1)];
            else
                error('Direction must be forward or inv, not %s', DIRECTION)
            end
            
            % Reduce number of trig functions
            cosA = cos(angles);
            sinA = sin(angles);
            
            
            switch CONVENTION
                
                case 'Bah'
                    
                    %     ROTATION_MATRIX = Rz(angles(3)) * Rx(angles(2)) * Rz(angles(1));
                    ROTATION_MATRIX = [cosA(3),-sinA(3),0;...
                        sinA(3),cosA(3),0;...
                        0,0,1] * ...
                        [1,0,0; ...
                        0,cosA(2),-sinA(2);...
                        0,sinA(2),cosA(2)] * ...
                        [cosA(1),-sinA(1),0;...
                        sinA(1),cosA(1),0;...
                        0,0,1] ;
                    
                case 'TILT'
                    
                    ROTATION_MATRIX =  [cosA,0,sinA; ...
                        0,1,0;...
                        -sinA,0,cosA];
                    
                    
                case 'SPIDER'
                    
                    
                    %     ROTATION_MATRIX = Rz(angles(3)) * Ry(angles(2)) * Rz(angles(1));
                    
                    ROTATION_MATRIX = [cosA(3),-sinA(3),0;...
                        sinA(3),cosA(3),0;...
                        0,0,1] * ...
                        [cosA(2),0,sinA(2); ...
                        0,1,0;...
                        -sinA(2),0,cosA(2)] * ...
                        [cosA(1),-sinA(1),0;...
                        sinA(1),cosA(1),0;...
                        0,0,1] ;
                    
                case 'Helical'
                    
                    
                    %   ROTATION_MATRIX = Ry(angles(3)) * Rx(angles(2)) * Ry(angles(1));
                    
                    ROTATION_MATRIX = [cosA(3),0,sinA(3); ...
                        0,1,0;...
                        -sinA(3),0,cosA(3)] * ...
                        [1,0,0; ...
                        0,cosA(2),-sinA(2);...
                        0,sinA(2),cosA(2)] * ...
                        [cosA(1),0,sinA(1); ...
                        0,1,0;...
                        -sinA(1),0,cosA(1)];
                    
                case 'IMOD'
                    
                    cosA = cos(angles);
                    sinA = sin(angles);
                    
                    %   ROTATION_MATRIX = Rz(angles(3)) * Ry(angles(2)) * Rx(angles(1));
                    
                    ROTATION_MATRIX = [cosA(3),-sinA(3),0;...
                        sinA(3),cosA(3),0;...
                        0,0,1] * ...
                        [cosA(2),0,sinA(2); ...
                        0,1,0;...
                        -sinA(2),0,cosA(2)] * ...
                        [1, 0, 0; ...
                        0, cosA(1),-sinA(1);...
                        0, sinA(1),cosA(1)] ;
                    
                    
                    
                    
                    
                    %   ROTATION_MATRIX = Rz(angles(3)) * Ry(angles(2)) * Rx(angles(1));
                case 'cisTEM'
                    ROTATION_MATRIX = [[cosA(3),sinA(3),0;...
                        -sinA(3),cosA(3),0;...
                        0,0,1] * ...
                        [cosA(2),0,-sinA(2); ...
                        0,1,0;...
                        sinA(2),0,cosA(2)] * ...
                        [1, 0, 0; ...
                        0, cosA(1),-sinA(1);...
                        0, sinA(1),cosA(1)] ]';
                    
                    % I'm not sure why the negative sign is swapped only for the Y-axis
                    
                otherwise
                    error('Convention must be Bah,SPI,Helical, not %s', CONVENTION)
            end
            
        end % end of function defineMatrix.
        
        %     case 'Protomo'
        %         % passive, intrinsic, Z X Z
        %         % i3euler e1 e2 e3
        %
        %         if strcmpi(dir,'forward')
        %
        %         elseif strcmpi(dir, 'inv')
        %             ang = -1.* [ang(3), ang(2), ang(1)];
        %
        %
        %         elseif strcmpi(dir, 'i3')
        %             ang = [ang(3), ang(2), ang(1)];
        
        %         end
        %
        %         RotMat = Rz(ang(3)) * Rx(ang(2)) * Rz(ang(1));
        %
        %
        %     case 'Imod'
        %         % active, extrinsic, Z Y X
        %
        %         if strcmpi(dir, 'forward')
        %             ang = -1 .* ang ;
        %         end
        %
        %         RotMat = Rx(ang(3))*Ry(ang(2))*Rz(ang(1)) ;
        %
        %     case 'Spider'
        %         % passive, extrinsic Z Y Z
        %         % Note that in their documents they refer to the "object"
        %         % rotating clockwise, which sounds active, but this is the
        %         % same as the CS anti-clockwise, which is just a passive
        %         % (alias) rotation. I believe Frealign, and Relion also use.
        %
        %         % Spider puts the origin at top left, with first z on top
        %
        %         RotMat = Rz(-e3)*Ry(-e2)*Rz(-e1) ;
        %
        %     case '2d'
        %         % active rotation, second two euler angles are dummy var
        %
        %        RotMat = Rz(e1);
        %        RotMat = RotMat(1:2,1:2) ;
        %
        %    case 'NegProtomo'
        %         % passive, intrinsic, Z X Z
        %         % i3euler e1 e2 e3
        %
        %
        %        RotMat = Rz(-ang(1)) * Rx(-ang(2)) * Rz(-ang(3)) ;
        %
        % end
        
        
        
        
    end
end

