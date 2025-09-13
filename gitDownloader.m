clc
clear
repoPath   = 'C:\irec-2025-analysis';   % Local clone of the repo
targetFile = 'rocket_files/IREC_2025_M6000ST-0.ork'; % must use forward slashes
outputDir  = fullfile(repoPath, 'downloaded_versions');
metadataFile = fullfile(outputDir, 'file_versions_metadata.csv');

if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

cd(repoPath);

% Prepare metadata file
fid_meta = fopen(metadataFile, 'w');
fprintf(fid_meta, "Commit,Author,Date,FilePath\n");

% Get commit list
[status, commitList] = system('git rev-list HEAD');
if status ~= 0
    error('Could not retrieve commit list');
end
commits = strsplit(strtrim(commitList), '\n');

for i = 1:length(commits)
    commit = strtrim(commits{i});
    fprintf('Checking commit %s\n', commit);

    % Check if file exists in this commit
    checkCmd = sprintf('git ls-tree -r %s -- "%s"', commit, targetFile);
    [chkStatus, chkOut] = system(checkCmd);

    if chkStatus == 0 && ~isempty(strtrim(chkOut))
        % File exists → extract metadata
        metaCmd = sprintf('git show -s --format="%%H,%%an,%%ad" --date=iso %s', commit);
        [metaStatus, metaOut] = system(metaCmd);

        if metaStatus == 0
            metaFields = strtrim(metaOut);
            % Save file contents
            getCmd = sprintf('git show %s:"%s"', commit, targetFile);
            [getStatus, fileData] = system(getCmd);

            if getStatus == 0
                outFile = fullfile(outputDir, sprintf('%s_%s', commit, strrep(targetFile, '/', '_')));
                fid = fopen(outFile, 'w');
                fwrite(fid, fileData);
                fclose(fid);

                % Write metadata row
                fprintf(fid_meta, "%s,%s\n", metaFields, outFile);
                fprintf('  Saved version to %s\n', outFile);
            end
        end
    end
end

fclose(fid_meta);
fprintf('Metadata written to %s\n', metadataFile);
