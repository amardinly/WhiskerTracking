search_folder = 'E:\Alan\180620_9122_2\';
struct = load(['E:\Alan\180610_9122_2_nu_track\180610_9122_2.mat']);
%struct = load(['Z:\holography\Data\hayley\expstruct\180612_7819_calib.mat']);
struct = struct.ExpStruct;
stims_strings = struct.InitialStimList;
stims = zeros(1, length(stims_strings));
for i=1:length(stims_strings)
    
    temp = stims_strings{i};
    stims(i) = str2double(temp);
end
% stims = struct.StimulusData;
stims = stims(2:end);

%%

tracked_files = dir([search_folder '*_tracked_data.mat']);
mean_pres = zeros(1, length(tracked_files));
peak_pres = zeros(1, length(tracked_files));
mean_durs = zeros(1, length(tracked_files));
peak_durs = zeros(1, length(tracked_files));
velocities_per_vid = {};
good_framesy = {};
for i=1:length(tracked_files)
    res = load([search_folder tracked_files(i).name]);
    
    centroids = res.centroids;
    good_frames = res.good_frames;
    [gf, v, mp, pp, md, pd] = get_summarized_velocity(centroids, good_frames);
    velocities_per_vid{i} = v;
    good_framesy{i} = gf;
    mean_pres(i) = mp;

    peak_pres(i) = pp;
    mean_durs(i) = md;
    peak_durs(i) = pd;
end


%% now exclude ones with whisker movement prior to things
dont_use = zeros(1, length(mean_pres));
for i=1:length(mean_pres)
    if isnan(mean_durs)
        dont_use(i)=1;
    end
    if abs(mean_durs(i)-mean_pres(i)) < .2*max(mean_durs(i), mean_pres(i)) || ...
            mean_pres(i) - mean_durs(i) > .3*max(mean_durs(i), mean_pres(i))
        dont_use(i)=1;
    end
end
%%
figure;
tracked_frames = zeros(1,length(good_framesy));
for i=1:length(velocities_per_vid)
    subplot(10,10,i);
    
    tracked_frames(i) = length(good_framesy{i});
    plot(good_framesy{i},velocities_per_vid{i}(good_framesy{i}));
    if dont_use(i)
        plot(good_framesy{i},velocities_per_vid{i}(good_framesy{i}), 'Color','red');
    end
    hold on;
    temp=ylim;
    plot([15 15], [0 temp(2)], 'Color', 'black')
        title(i);
end

%%
stim_levels = unique(stims);
plot_order = [];
for lev=stim_levels
    plot_order = [plot_order find(stims == lev)];
end

%%
figure;
ax=[];
for j=1:length(velocities_per_vid)
    subplot(8,8,j);
    ax = [ax gca];
    i = plot_order(j);
    plot(good_framesy{i},velocities_per_vid{i}(good_framesy{i}));
    if dont_use(i)
        plot(good_framesy{i},velocities_per_vid{i}(good_framesy{i}), 'Color','red');
    end
    temp=ylim;
    hold on; plot([15 15], [0 200], 'Color', 'black', 'LineWidth', 2)
        title(stims(i));
%         if mod(j,10) ~= 1
%         set(gca,'Yticklabel',[]) 
% set(gca,'Xticklabel',[]) %to just get rid of the numbers but leave the ticks.
%         end
end
% linkaxes(ax, 'xy')
%%
stims_with_bad_removed = stims(1:end);
stims_with_bad_removed(find(dont_use==1)) = -10;
stim_levels = unique(stims);
figure; hold on;
for lev = stim_levels
    disp([int2str(lev) ':   ' int2str(length(find(stims_with_bad_removed==lev)))])
    vals = peak_durs(find(stims_with_bad_removed==lev));
    vals = vals(~isnan(vals));
    errorbar(lev, mean(vals), std(vals)/sqrt(length(vals)), 'Color', 'black');
    scatter(lev, median(vals), 60, 'MarkerEdgeColor', 'red', 'MarkerFaceColor', 'red', 'MarkerFaceAlpha', .2);
    scatter(repmat(lev, 1, length(vals)), vals, 25, 'MarkerEdgeColor', 'blue',...
    'MarkerEdgeAlpha',.3);
end
hold off;

%% without outliers
stims_with_bad_removed = stims;
%stims_with_bad_removed(find(dont_use==1)) = -10;
stim_levels = unique(stims2);
figure; hold on;
medians = [];
for i = 1:length(stim_levels)
    lev = stim_levels(i);
    disp([int2str(lev) ':   ' int2str(length(find(stims_with_bad_removed==lev)))])
    vals = peak_durs(find(stims_with_bad_removed==lev));
    vals = vals(~isnan(vals));
    %get outlier values
        % Compute the median absolute difference
        meanValue = mean(vals);
        % Compute the absolute differences.  It will be a vector.
        absoluteDeviation = abs(vals - meanValue);
        % Compute the median of the absolute differences
        mad = median(absoluteDeviation);
        % Find outliers.  They're outliers if the absolute difference
        % is more than some factor times the mad value.
        sensitivityFactor = 6 % Whatever you want.
        thresholdValue = sensitivityFactor * mad;
        outlierIndexes = abs(absoluteDeviation) > thresholdValue;
        
        vals = vals(~outlierIndexes);
    errorbar(lev, mean(vals), std(vals)/sqrt(length(vals)), 'Color', 'black');
    medians = [medians median(vals)];
    scatter(lev, median(vals), 60, 'MarkerEdgeColor', 'red', 'MarkerFaceColor', 'red', 'MarkerFaceAlpha', .2);
    %scatter(repmat(lev, 1, length(vals)), vals, 25, 'MarkerEdgeColor', 'blue',...
    %'MarkerEdgeAlpha',.3);
end
ylabel('Peak Velocity')

yyaxis right
plot(stats.psy(:,1), stats.psy(:,2), 'k+--');
ylabel('Percent Hit')
xlabel('Stimulus Strength')
left_color = [1 1 1];
right_color = [1 1 1];
set(gcf,'defaultAxesColorOrder',[left_color; right_color]);

hold off;


%%
% % % 
% x9245_2.mean_durs = mean_durs;
% x9245_2.peak_durs = peak_durs;
% x9245_2.mean_pres = mean_pres;
% x9245_2.peak_pres = peak_pres;
% x9245_2.stims = stims;
% x9245_2.dont_use = dont_use;
