function [original_eers, tif_flag] = getOriginalEERs(configuration)
tif_flag = 0;
if isfield(configuration, "tomogram_input_prefix")...
        && iscell(configuration.tomogram_input_prefix)
    counter = 1;
    for i = 1:length(configuration.tomogram_input_prefix)
        for j = 1:length(configuration.data_path)
            mrc_path(counter) = configuration.data_path{j} + string(filesep)...
                + configuration.tomogram_input_prefix{i} + "*.eer";
            counter = counter + 1;
        end
    end
elseif isfield(configuration, "tomogram_input_prefix")...
        && configuration.tomogram_input_prefix ~= ""
    mrc_path = configuration.data_path + string(filesep)...
        + configuration.tomogram_input_prefix + "*.eer";
else
    mrc_path = configuration.data_path;
    if ~contains(mrc_path, ".eer")
        mrc_path = mrc_path + string(filesep) + "*.eer";
    end
end

counter = 1;
for i = 1:length(mrc_path)
    original_eers{counter} = dir(mrc_path{i});
    if isempty(original_eers{counter})
        continue;
    end
    counter = counter + 1;
end

% if iscell(original_tifs)
%     original_files_tmp = struct("name", '', "folder", '', "date", '',...
%         "bytes", 0, "isdir", false, "datenum", 0);
%     for i = 1:length(original_tifs)
%         if i == 1
%             original_files_tmp(1:length(original_tifs{i})) = original_tifs{i};
%         else
%             original_files_tmp(end + 1:end + length(original_tifs{i})) = original_tifs{i};
%         end
%     end
%     original_tifs = original_files_tmp;
% end
end

