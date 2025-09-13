clc
clear

repoPath   = 'C:\irec-2025-analysis';   % Local clone of the repo
targetFile = 'rocket_files/IREC_2025_M6000ST-0.ork'; % file path (use / not \)
outputDir  = fullfile(repoPath, 'downloaded_versions');
metadataFile = fullfile(outputDir, 'file_versions_metadata.csv');

if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

cd(repoPath);

% Prepare metadata file
fid_meta = fopen(metadataFile, 'w');
fprintf(fid_meta, "Commit,Author,Date,FilePath\n");

% Get only commits that touched the file (following renames)
logCmd = 'git log --pretty=format:"%%H"';
[status, commitList] = system(logCmd);
if status ~= 0
    error('Could not retrieve commit history for %s', targetFile);
end
commits = strsplit(strtrim(commitList), '\n');

for i = 1:length(commits)
    commit = strtrim(commits{i});
    fprintf('Extracting from commit %s\n', commit);

    % Get metadata
    metaCmd = sprintf('git log -1 --format="%%H,%%an,%%ad" --date=iso %s -- %s', commit, targetFile);

    [metaStatus, metaOut] = system(metaCmd);

    if metaStatus == 0
        outFile = fullfile(outputDir, sprintf('%s_%s', commit, strrep(targetFile, '/', '_')));
        
        % Use Java ProcessBuilder to dump binary directly
        pb = java.lang.ProcessBuilder({'git','show',sprintf('%s:%s',commit,targetFile)});
        pb.directory(java.io.File(repoPath));
        pb.redirectOutput(java.io.File(outFile));
        pb.redirectErrorStream(true);
        process = pb.start();
        process.waitFor();

        % Record metadata row
        fprintf(fid_meta, "%s,%s\n", strtrim(metaOut), outFile);
        fprintf('  Saved version to %s\n', outFile);
    else
        fprintf('  Skipped %s (metadata error)\n', commit);
    end
end

fclose(fid_meta);
fprintf('Metadata written to %s\n', metadataFile);
