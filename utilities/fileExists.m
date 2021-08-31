function exists = fileExists(fileName)
coder.extrinsic("isfile");
% global environmentProperties;
% TODO: write function for detecting if MATLAB release is higher or lower
%  than some specified release

% NOTE: For R2017b and following releases
% if environmentProperties.matlab_release == "2018b"
    if isfile(fileName)
        exists = true;
    else
        exists = false;
    end
% else
%     % NOTE: For R2017a and previous releases
%    
%     % NOTE: Be sure to specify an absolute path for the file name. The "exist"
%     %  function searches all files and folders on the search path, which can
%     %  lead to unexpected results if multiple files with the same name exist.
%     if exist(fileName, 'file') == 2
%         exists = true;
%     else
%         exists = false;
%     end
% end
end

