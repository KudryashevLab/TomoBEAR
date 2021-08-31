function table = processCCVolume(configuration, template_matching_path)

if isempty(configuration)
    configuration.ellipsoid_smoothing_pixels = 5;
    configuration.threshold_standard_deviation = 3;
end


dir_list = dir(template_matching_path + "*");
for i = 1:length(dir_list)
    splitted_folder_name_by_dot = strsplit(dir_list(i).name, ".");
    splitted_folder_name_by_underscore = strsplit(splitted_folder_name_by_dot{1:end-1}, "_");
    narot_string = splitted_folder_name_by_underscore{end};
    narot{i} = str2num(narot_string);
    
    cc_map{i} = dread(char(dir_list(i).folder + string(filesep) + dir_list(i).name + string(filesep) + "cc.mrc"));
    tdrot_map{i} = dread(char(dir_list(i).folder + string(filesep) + dir_list(i).name + string(filesep) + "tdrot.mrc"));
    tilt_map{i} = dread(char(dir_list(i).folder + string(filesep) + dir_list(i).name + string(filesep) + "tilt.mrc"));
end


% TODO: wipeout dark edges from cc volume, perhaps try high pass filter
cc_map_threshold_indices = cc_map{1} < mean(cc_map{1}(:)) + (configuration.threshold_standard_deviation * std(cc_map{1}(:)));
cleaned_cc_map = cc_map{1};
cleaned_cc_map(cc_map_threshold_indices) = 0;
regional_maxima = imregionalmax(cleaned_cc_map);

% TODO: calculate size for given particle
mask_peak = gpuEllipsoid(10, size(cc_map{i}, 2), size(cc_map{i}) / 2 + 1, configuration.ellipsoid_smoothing_pixels);

N = 200; % ppt

tab_all = [];
for i = 1:length(cc_map)
    
        %try
        tab_tomo = dynamo_table_blank(N);
        tab_tomo(:,14) = maxangles(i,1);
        tab_tomo(:,15) = maxangles(i,2);
        tab_tomo(:,20) = i;
        
        tab_tomo(:,1) = max(tab_all(:,1))+1:max(tab_all(:,1))+N;

        cc = dread(['TM/tomo_' num2strtotal(i,3) '.TM/cc.mrc']);
        cc1 = cc;
        
        while any(regional_maxima, "all")
            [a b] = dynamo_peak_subpixel(cc1);
            disp([p a b]);
            tab_tomo(p,24:26) = a*2-[17 0 231];
            tab_tomo(p,10) = b;
            nmask = dnan(tom_shift(mask_peak,double(a-[240 240 240])));
            cc1 = cc1.*(1-nmask);
        end
        % merge tables here
        tomo = dread(['tomos/tomo'  num2strtotal(i,3) '_bin4.mrc']);
        tomo =  dynamo_normalize_roi(tomo);
        dtcrop(tomo, tab_tomo, 'particles_bin4_tmp',100, 'allow_padding', 1);
        tab = dread('particles_bin4_tmp/crop.tbl');
        tab_all(end+1:end+N,:) = tab;
        system("mv particles_bin4_tmp/*em particles_bin4/");
        dwrite(tab_all, ['tab_ini_' num2str(size(tab_all,1)) '.tbl']);
        %end
end
end
