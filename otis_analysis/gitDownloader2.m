clc
clear

% Repo info
repo = 'RIT-Launch-Initiative/irec-2025-analysis';
filename = 'IREC_2025_M6000ST-0.ork';

% Get commits for this file
commits_api = ['https://api.github.com/repos/' repo '/commits?path=' filename '&per_page=100'];
options = weboptions('Timeout', 30);

commits = webread(commits_api, options);

% Output folder
output_folder = 'irec_files';
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

% Metadata storage (cell array first, then convert)
metadata = {};

for i = 1:length(commits)
    sha = commits(i).sha;
    commit_date = commits(i).commit.committer.date;
    author = commits(i).commit.committer.name;

    url = ['https://raw.githubusercontent.com/' repo '/' sha '/' filename];
    out_file = fullfile(output_folder, [sha '_' filename]);

    % Initialize entry
    entry = struct( ...
        'sha', sha, ...
        'date', commit_date, ...
        'author', author, ...
        'url', url, ...
        'output_file', out_file, ...
        'status', '' ...
    );

    try
        websave(out_file, url, options);
        fprintf('[OK] %s saved → %s\n', sha, out_file);
        entry.status = 'downloaded';
    catch ME
        if contains(ME.message, '404')
            fprintf('[SKIP] %s → file not present in this commit\n', sha);
            entry.status = 'not found';
        else
            fprintf('[ERROR] %s: %s\n', sha, ME.message);
            entry.status = ['error: ' ME.message];
        end
    end

    metadata{end+1} = entry; %#ok<SAGROW>
end

% Convert to struct array
metadata_struct = [metadata{:}];

% Save MATLAB array
save(fullfile(output_folder, 'metadata.mat'), 'metadata_struct');

fprintf('\n✅ Metadata saved to %s\n', fullfile(output_folder, 'metadata.mat'));
