clear
clc

% Load the MAT file
data = load('irec_files/metadata.mat');

% Access the struct array
commits = data.metadata_struct;

% Now you can extract fields
all_sha    = {commits.sha};     % cell array of all SHAs
all_dates  = {commits.date};    % commit dates
all_authors= {commits.author};  % commit authors
all_outf   = {commits.output_file}; 

% Example: print first 5 SHAs
% disp(all_outf(1:5));

component = "irec-2025";

for i = 1:length(all_outf)
    try
        rockfile = openrocket(all_outf{i});
     catch ME
        % Skip files that fail to load
        if contains(ME.message, 'RocketLoadException') || ...
           contains(ME.message, 'Unsupported or corrupt file')
            fprintf("[SKIP] %s → Corrupted or unsupported file\n", all_outf{i});
        else
            fprintf("[ERROR] %s → %s\n", all_outf{i}, ME.message);
        end
        continue
    end

    
    [CG, mass, moi] = rockfile.massdata('LAUNCH');
    fprintf("Launch Mass: %.3f kg\n", mass);





    rocket = rockfile.component(name = "OTIS");
    if rocket == 0
        rocket = rockfile.component(name = "irec-2025")
    end

    comp_mass = MassCalculator.getMass(rocket);
    fprintf("Rocket Mass: %.3f kg\n", comp_mass);


end