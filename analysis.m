
search_folder = 'E:\Alan\180611_9122\';

tracked_files = dir([search_folder '*_tracked_data.mat']);
%%
x8923_2.y_disp = zeros(1, length(tracked_files)-1);
x8923_2.x_disp = zeros(1, length(tracked_files)-1);
x8923_2.disp = zeros(1, length(tracked_files)-1);
x8923_2.usable_dur_cents = {};
x8923_2.usable_pre_cents = {};


velocities_per_vid = {};
good_framesy = {};
figure;
do_plot = false
for i=1:length(tracked_files)
    res = load([search_folder tracked_files(i).name]);
    
    centroids = res.centroids;
    good_frames = res.good_frames;
    filt_cent = sgolayfilt(centroids.',3,5);
    filt_cent = filt_cent.';
    good_frames = find(good_frames==1);
    
    usable_pre = good_frames(good_frames <= 17 & good_frames > 10);
    usable_dur = good_frames(good_frames < 45 & good_frames > 17);
    if ~isempty(usable_pre) && ~isempty(usable_dur)
    x8923_2.y_disp(i) = filt_cent(1, max(usable_pre)) - max(filt_cent(1, usable_dur));
    x8923_2.x_disp(i) = filt_cent(2, max(usable_pre)) - max(filt_cent(2, usable_dur));
    x8923_2.disp(i) = sqrt((filt_cent(1, max(usable_pre)) - max(filt_cent(1, usable_dur)))^2 ...
        + (filt_cent(2, max(usable_pre)) - max(filt_cent(2, usable_dur)))^2);
    x8923_2.usable_pre_cents{i} = filt_cent(:, usable_pre);
    x8923_2.usable_dur_cents{i} = filt_cent(:, usable_dur);
    end
    if do_plot
            subplot(10,11,i)

    plot(filt_cent(2,usable_dur), -filt_cent(1,usable_dur));
    hold on;
    plot(filt_cent(2,usable_pre), -filt_cent(1,usable_pre));
    daspect([1 1 1])
    
    hold off;
    set(gcf, 'Position', [100, 100, 100, 100])
    title(tracked_files(i).name(end-20:end-17))
    end
%     [gf, v, mp, pp, md, pd] = get_summarized_velocity(centroids, good_frames);
%     velocities_per_vid{i} = v;
%     good_framesy{i} = gf;
%     mean_pres(i) = mp;
% 
%     peak_pres(i) = pp;
%     mean_durs(i) = md;
%     peak_durs(i) = pd;
end


filt_cent = sgolayfilt(centroids.',3,5);
filt_cent = filt_cent.';


%%
figure; hold on;
mean_durs = x8923_2.disp;
stims = stims;
dont_use = dont_use;
stims_with_bad_removed = stims;
stims_with_bad_removed(find(dont_use==1)) = -10;
stim_levels = unique(stims);
find(stims==lev)
length(mean_durs)
for lev = stim_levels
    disp([int2str(lev) ':   ' int2str(length(find(stims_with_bad_removed==lev)))])
    vals = x8923_2.disp(find(stims_with_bad_removed==lev)+1);
    vals = vals(~isnan(vals));
    errorbar(lev, mean(vals), std(vals)/sqrt(length(vals)), 'Color', 'black');
    scatter(lev, median(vals), 60, 'MarkerEdgeColor', 'black', 'MarkerFaceColor', 'black', 'MarkerFaceAlpha', .2);
    scatter(repmat(lev, 1, length(vals)), vals, 25, 'MarkerEdgeColor', 'black',...
    'MarkerEdgeAlpha',.3);
end
