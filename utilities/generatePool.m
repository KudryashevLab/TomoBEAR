function generatePool(cores, force, path, debug)
persistent previous_cores;
if isempty(previous_cores)
	previous_cores = 0;
end

poolobj = gcp('nocreate');
pc = parcluster('local');
if string(path) ~= ""
    pc.JobStorageLocation = char(path);
end

if force || previous_cores == 0 || previous_cores ~= cores
    % get number of cores available on the used machine
    % and assigned to MATLAB
    if cores <= 1
        poolsize = round(feature('numcores') / cores);
    else
        poolsize = cores;
    end
    
    % check whether required poolsize do not exceed number of workers
    % allowed by used parcluster profile settings
    if poolsize > pc.NumWorkers
        poolsize = pc.NumWorkers;
    end
    
    % open a pool
    if isempty(poolobj)
        disp("INFO:poolsize: " + poolsize);
        poolobj = parpool(pc, poolsize);
    else
        current_poolsize = poolobj.NumWorkers;
        if current_poolsize ~= poolsize
            disp("INFO:poolsize: " + poolsize);
            delete(poolobj);
            poolobj = parpool(pc, poolsize);
        end
    end
end
previous_cores = cores;
end


