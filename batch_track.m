vidFolder = '/mnt/modulation/frankenshare/MagnetTracking/';
saveFolder = '/mnt/modulation/amardinly/MagnetTracking/AlanTrackResults/';
files = dir(vidFolder);
files(1:2) = [];
dirFlags = [files.isdir];
% Extract only those that are directories.
subFolders = files(dirFlags);
[dates, idx] = sort([subFolders.datenum]);
subFolders = subFolders(idx);
subFolders = subFolders(1:16); %temp, only track the oldest ones on this computer
% select name of directories
subFolders = {subFolders.name};
startCentroids = {};
trackFolder = ones(1, length(subFolders)); %will remove folders if empty, ect
%get start centroid for folder
for foldind = 1:length(subFolders)
    if contains(subFolders{foldind}, 'online') %for now don't track calibration
        trackFolder(foldind) = 0;
        continue
    end
    search_folder = [vidFolder subFolders{foldind} '/'];
    files = dir([search_folder '*.tif']);
    if isempty(files)
        trackFolder(foldind) = 0;
    else
        try
            centroid = getStartCentroid([search_folder files(1).name]);
            if ~isempty(centroid)
                startCentroids{foldind} = centroid;
            else
                trackFolder(foldind) = 0;
                disp(subFolders{foldind});
            end
        catch
            trackFolder(foldind) = 0;
            disp(subFolders{foldind});
        end
    end
end

%%
%then go through and actually analyze the videos.
for foldind = 1:length(subFolders)
    if trackFolder(foldind)
        track_whiskers2([vidFolder subFolders{foldind} '/'], 'startCentroid',...
            startCentroids{foldind}, 'saveFolder',...
        saveFolder, 'savename', subFolders{foldind})
    end
end

save([saveFolder 'TrackStatus01'], 'subfolders', 'trackFolder');
