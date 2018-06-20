%% analyze
%TODO: make it choose the closest blob. For offline, make background chosen
%from a random set of the frames where the deflection is occuring (15-50?)
%from a random set of videos
%consider switching to alans method of threshing.

%'E:\Alan\180613_9122\' has issues bc its toooooo big

% imagesc(nu(:,:,2)-mean(cat(3,mean(nu,3), bg),3));
search_folder = 'E:\Alan\180613_9122\'
n_vids = 300 %onlineStruct.trialNum;
current_n = 0;
do_plot=true
% meanPreStimVels = zeros(1, n_vids);
% peakDurStimVels = zeros(1, n_vids);
% meanDurStimVels = zeros(1, n_vids);
% doUse = zeros(1, n_vids);
files = dir([search_folder '*.tif']);

bg = get_background([search_folder files(1).name]);
%%
for i=45:length(files)
    if true%mod(i,15)==0
        [centroids, good_frames] = track_whisker_single_video_debug(...
                    [search_folder files(i).name], bg, true, false, true);
    else
        [centroids, good_frames] = track_whisker_single_video(...
                    [search_folder files(i).name], bg, false, false, true);
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
