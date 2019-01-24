%% analyze
%TODO: make it choose the closest blob. For offline, make background chosen
%from a random set of the frames where the deflection is occuring (15-50?)
%from a random set of videos
%consider switching to alans method of threshing.

%'E:\Alan\180613_9122\' has issues bc its toooooo big

% imagesc(nu(:,:,2)-mean(cat(3,mean(nu,3), bg),3));
clear all;
search_folder = 'E:\Alan\180621_9149\'
do_plot=false
use_beh_file = false
% meanPreStimVels = zeros(1, n_vids);
% peakDurStimVels = zeros(1, n_vids);
% meanDurStimVels = zeros(1, n_vids);
% doUse = zeros(1, n_vids);
files = dir([search_folder '*.tif']);


%make this find a 255 deflection
if use_beh_file
    beh_file = dir([search_folder '*BoxRIG.txt']);%'9122_2018_6_14_14_32_BoxRIG.txt';
    beh_file = beh_file.name;
    Trials = readBehaviorData([search_folder beh_file]);
    first_255 = find(Trials(1,:)==255);
    first_255 = first_255(1);
    bg = get_background([search_folder files(first_255).name]);
else
    bg = get_background([search_folder files(1).name]);
end

%%
save=true;
for i=25:length(files)
    if mod(i,25)==0
        [centroids, good_frames] = track_whisker_single_video2(...
                    [search_folder files(i).name], bg, false, false, save, false);
    elseif i < 10
        [centroids, good_frames] = track_whisker_single_video2(...
                    [search_folder files(i).name], bg, true, false, save, false);
    else
        [centroids, good_frames] = track_whisker_single_video2(...
                    [search_folder files(i).name], bg, false, false, save, false);
    end
            if do_plot
                [gf, v, mp, pp, md, pd] = get_summarized_velocity(centroids, good_frames);
                doUse = determine_if_use(mp, md);
                
                figure(3)
                subplot(ceil(sqrt(n_vids)), ceil(sqrt(n_vids)), i);
                plot(gf, v(gf));
                if ~doUse; plot(gf, v(gf), 'Color', 'red');
                end
                pause(.1)
            end
          
end
