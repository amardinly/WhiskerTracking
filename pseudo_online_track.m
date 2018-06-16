clear all; close all;
struct_folder = 'Z:\holography\Data\Magnet\OnlineWhiskerTransfer\';
do_plot = true;


%find what the old file's date was
theFDir = dir([struct_folder '*.mat']);
for j = 1:numel(theFDir);
prevDateNum(j) = theFDir(j).datenum;
end
prevDateNum = max(prevDateNum);

%wait for a file written after the prev date
newDateNum =0;
while newDateNum <= prevDateNum;
    newDir = dir([struct_folder '*.mat']);
    for j = 1:numel(newDir);
    datenums(j) = newDir(j).datenum;
    end
    [newDateNum desired_ind]=max(datenums);
    pause(.1)
end
    disp('found new file');

%read in file
%[~, desired_ind] = max(dir([struct_folder '*.mat']).datenum);
temp = dir([struct_folder '*mat']);
onlineStruct = load([struct_folder temp(desired_ind).name]);
onlineStruct = onlineStruct.onlineStruct;
stims_strings = onlineStruct.stims;

%convert stims to a matrix of numbers
stims = zeros(1, length(stims_strings));
for i=1:length(stims_strings)
    
    temp = stims_strings{i};
    stims(i) = str2double(temp);
end

%create search folder and wait for it to exist
search_folder = strcat('E:\Alan\',datestr(now,'yymmdd'), '_', onlineStruct.mouseID, '_online\');

while ~exist(search_folder, 'dir')
    pause(.1)
end

%% analyze
n_vids = onlineStruct.trialNum;
current_n = 0;
% meanPreStimVels = zeros(1, n_vids);
% peakDurStimVels = zeros(1, n_vids);
% meanDurStimVels = zeros(1, n_vids);
% doUse = zeros(1, n_vids);
while current_n < n_vids
    if length(dir([search_folder '*.tif'])) > current_n
        current_n = current_n + 1
        if current_n == 2;
            files = dir([search_folder '*.tif']);
            bg = get_background([search_folder files(current_n-1).name]);
            %disp('got background')
        elseif current_n > 2
            files = dir([search_folder '*.tif']);
            [centroids, good_frames] = track_whisker_single_video([search_folder files(current_n-1).name], bg, false, false, true);
            if do_plot
                [gf, v, mp, pp, md, pd] = get_summarized_velocity(centroids, good_frames);
                doUse = determine_if_use(mp, md);
                
                figure(1)
                subplot(ceil(sqrt(n_vids)), ceil(sqrt(n_vids)), current_n-1);
                plot(gf, v(gf));
                if ~doUse; plot(gf, v(gf), 'Color', 'red');
                end
                title(stims(current_n-1));
                if doUse
                    figure(2); hold on;
                    scatter(stims(current_n-1), pd); hold off;
                end
                pause(.1)
            end
        end
        %if its the last one, pause to ensure vid is written then analyze
        if current_n == n_vids
            pause(2);
            files = dir([search_folder '*.tif']);
            [centroids, good_frames] = track_whisker_single_video([search_folder files(current_n).name], bg, false, false, true);
            if do_plot
                [gf, v, mp, pp, md, pd] = get_summarized_velocity(centroids, good_frames);
                doUse = determine_if_use(mp, md);
                
                figure(1)
                subplot(ceil(sqrt(n_vids)), ceil(sqrt(n_vids)), current_n-1);
                plot(find(gf==1), v(find(gf==1)));
                if ~doUse; plot(find(gf==1), v(find(gf==1)), 'Color', 'red');
                end
                title(stims(current_n));
                
                if doUse
                    figure(2); hold on;
                    scatter(stims(current_n), pd); hold off;
                end
            end
        end
    else
        pause(.1)
    end
end
