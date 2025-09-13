clear
clc

% Load the MAT file
data = load('irec_files/metadata.mat');
commits = data.metadata_struct;

% Extract fields
all_sha    = {commits.sha};
all_dates  = {commits.date};
all_authors= {commits.author};
all_outf   = {commits.output_file};

component = "irec-2025";

masses = nan(length(all_outf),1);
dates  = NaT(length(all_outf),1,'TimeZone','UTC');   % Preallocate with UTC

for i = 1:length(all_outf)
    try
        rockfile = openrocket(all_outf{i});
    catch ME
        if contains(ME.message, 'RocketLoadException') || ...
           contains(ME.message, 'Unsupported or corrupt file')
            fprintf("[SKIP] %s → Corrupted or unsupported file\n", all_outf{i});
        else
            fprintf("[ERROR] %s → %s\n", all_outf{i}, ME.message);
        end
        continue
    end

    % Mass data
    [CG, mass, moi] = rockfile.massdata('LAUNCH');
    masses(i) = mass;

    % Parse ISO 8601 string into datetime with UTC
    dates(i) = datetime(all_dates{i}, ...
        'InputFormat','yyyy-MM-dd''T''HH:mm:ss''Z', ...
        'TimeZone','UTC');

    fprintf("Rocket Mass: %.3f kg | Date: %s\n", mass, datestr(dates(i)));
end

info = table(dates, masses, 'VariableNames', {'Date','Mass'});
info = sortrows(info,'Date');

% Plot
figure;
plot(info.Date, info.Mass, '-o', 'LineWidth', 1.5);
xlabel('Date');
ylabel('Launch Mass (kg)');
title('Rocket Launch Mass Over Time');
grid on;
