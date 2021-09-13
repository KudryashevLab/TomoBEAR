function generatePool(cores, force, path)
persistent previous_cores;
if isempty(previous_cores)
	previous_cores = 0;
end
% global DEBUG
% NOTE: build in mode for interpretation
poolobj = gcp('nocreate'); % If no pool, do not create new one.

pc = parcluster('local');
if string(path) ~= ""
    pc.JobStorageLocation = char(path);
end

if force || previous_cores == 0 || previous_cores ~= cores %~DEBUG && 
    if isempty(poolobj)
        if cores <= 1
            poolsize = round(feature('numcores') / (1/cores));
        else
            poolsize = cores;
        end
        disp("INFO:poolsize: " + poolsize);
        poolobj = parpool(pc, poolsize);
    else
        current_poolsize = poolobj.NumWorkers;
        if cores <= 1
            poolsize = round(feature('numcores') / (1/cores));
        else
            poolsize = cores;
        end
        if current_poolsize ~= poolsize
            disp("INFO:poolsize: " + poolsize);
            delete(poolobj);
            poolobj = parpool(pc, poolsize);
        end
    end
end
previous_cores = cores;
end


