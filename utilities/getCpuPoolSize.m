function poolsize = getCpuPoolSize(cores, cores_requested)

% get number of cores available on the used machine
% and assigned to MATLAB
if cores <= 1
    if nargin == 1
        poolsize = round(feature('numcores') / cores);
    else
        poolsize = round(cores_requested / cores);
    end
else
    poolsize = round(cores);
end
    
% check whether required poolsize do not exceed number of workers
% allowed by used parcluster profile settings
pc = parcluster('local');
if poolsize > pc.NumWorkers
    poolsize = pc.NumWorkers;
end

end