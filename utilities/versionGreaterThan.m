function result = versionGreaterThan(version, version_to_be_compared_to, delimiter)
if nargin == 2
    delimiter = ".";
end
version_numbers_str = strsplit(version, delimiter);
version_numbers_to_be_compared_to_str = strsplit(version_to_be_compared_to, delimiter);
for i = 1:length(version_numbers_str)
    version_numbers(i) = str2double(version_numbers_str(i));
	version_numbers_to_be_compared_to(i) = str2double(version_numbers_to_be_compared_to_str(i));
end
if version_numbers(1) >= version_numbers_to_be_compared_to(1)
    result = true;
    if version_numbers(2) >= version_numbers_to_be_compared_to(2)
        result = true;
        if version_numbers(3) >= version_numbers_to_be_compared_to(3)
            result = true;
        else
            result = false;
        end
    else
        result = false;
    end
else
    result = false;
end
end

