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
    
    poolsize = getCpuPoolSize(cores);
    
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


