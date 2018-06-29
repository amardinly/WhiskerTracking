files = dir('E:/Alan/');
files(1:2) = []
dirFlags = [files.isdir];
% Extract only those that are directories.
subFolders = files(dirFlags);
% select name of directories
subFolders = {subFolders.name};
startCentroids = {};
no
%start by grabbing the start centroid for folder
for foldind = 1:length(subFolders)[0:5]
    search_folder = ['E:/Alan/' subFolders{foldind} '/']
    files = dir([search_folder '*.tif']);
    try
    startCentroids{foldind} = getStartCentroid([search_folder files(1).name]);
    catch
    end
end

%then go through and actually analyze the videos.
parfor foldind = 1:length(subFolders)
    track_whiskers2(['E:/Alan/' subFolders{foldind} '/'], 'startCentroid',...
        startCentroids{foldind}, 'saveFolder',...
    ['E:/Alan/' 'new_track_with_alan' '/'], 'savename', subFolders{foldind})
end
