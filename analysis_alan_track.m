search_folder = 'E:\Alan\Results\';
file = '180621_9149.mat';
struct = load([search_folder file]);

behFolder = 'Z:\amardinly\BehaviorData\';
behFile = '9149_2018_6_21_17_9_BoxRIG.txt';

Trials = readBehaviorData([behFolder behFile]);
%Trials2 = readBehaviorDataIncomplete([search_folder beh_file2]);
%Trials = [Trials1; Trials2];
dataOut.Trials = Trials;
stats = getBehaviorStats(dataOut);
length(Trials)


stims = Trials(1:end-1,1);
%%
traces = struct.WhiskerTrace;
weirdFuckUpLog = struct.weirdFuckUpLog;
mean_pres = zeros(1, length(traces));
peak_pres = zeros(1, length(traces));
mean_durs = zeros(1, length(traces));
peak_durs = zeros(1, length(traces));
length_things = length(traces);
disps = zeros(1, length_things);
x_disps = zeros(1, length_things);
y_disps = zeros(1, length_things);
velocities_per_vid = {};
good_framesy = {};
for i=1:length(traces)
    centroids = traces{i};
    bad_frames = find(weirdFuckUpLog(:,1)==i);
    bad_frames = weirdFuckUpLog(bad_frames, :);
    [gf, v, mp, pp, md, pd] = get_summarized_velocity(centroids, bad_frames, 'alan');
    velocities_per_vid{i} = v;
    good_framesy{i} = gf;
    mean_pres(i) = mp;

    peak_pres(i) = pp;
    mean_durs(i) = md;
    peak_durs(i) = pd;
        [good_frames, usable_pre_cents, usable_dur_cents, x_disp, y_disp, disp] = get_summarized_displacement(centroids, bad_frames, 'alan');

    x_disps(i) = x_disp;
    y_disps(i) = y_disp;
    disps(i) = disp;
end

%% do k means to exclude files
data = zeros(length(traces), length(velocities_per_vid{5})-1);
for i = 1:length(velocities_per_vid)
    if size(velocities_per_vid{i}(2:end), 2) < size(data,2)
        data(i, 1:size(velocities_per_vid{i}(2:end),2)) = velocities_per_vid{i}(2:end);
    else
        data(i, :) = velocities_per_vid{i}(2:end);
    end
end
zdata=zscore(data,[],2);
 Widx = kmeans(zdata,2);
 
%% alternate kmeans
data = zeros(length(traces), length(velocities_per_vid{5})-1);
for i = 1:length(velocities_per_vid)
    if size(velocities_per_vid{i}(2:end), 2) < size(data,2)
        data(i, 1:size(velocities_per_vid{i}(2:end),2)) = velocities_per_vid{i}(2:end);
    else
        data(i, :) = velocities_per_vid{i}(2:end);
    end
end
zdata=zscore(data,[],2);
 Widx2 = kmeans(zdata(:,1:20),2);
%%
figure()
subplot(1,2,1)
imagesc(data(find(Widx==1),:))
subplot(1,2,2)
imagesc(data(find(Widx==2),:))
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
for i=1:length(stim_levels)
    lev = stim_levels(i)
    plot_order = [plot_order; find(stims == lev)];
end

%%
figure;
ax=[];
for k=1:length(velocities_per_vid)
    subplot(10,10,k);
    ax = [ax gca];
    j=k+50
    i = plot_order(j);
    plot(velocities_per_vid{i}(1:40));
    if Widx(i)==1
        plot(velocities_per_vid{i}(1:40), 'Color','red');
    end
    temp=ylim;
    hold on; plot([25 25], [0 15], 'Color', 'black', 'LineWidth', 2)
        title([num2str(stims(i)) ': ' num2str(i)]); axis off;
%         if mod(j,10) ~= 1
%         set(gca,'Yticklabel',[]) 
% set(gca,'Xticklabel',[]) %to just get rid of the numbers but leave the ticks.
%         end
end
% linkaxes(ax, 'xy')
%%
stims_with_bad_removed = stims(1:end);
stims_with_bad_removed(find(Widx==1)) = -10;
stim_levels = unique(stims);
figure; hold on;
for i = 1:length(stim_levels)
    lev = stim_levels(i)
    %disp([int2str(lev) ':   ' int2str(length(find(stims_with_bad_removed==lev)))])
    vals = mean_durs(find(stims_with_bad_removed==lev));
    vals = vals(~isnan(vals));
    errorbar(lev, mean(vals), std(vals)/sqrt(length(vals)), 'Color', 'black');
        scatter(lev, median(vals), 60, 'MarkerEdgeColor', 'red', 'MarkerFaceColor', 'red', 'MarkerFaceAlpha', .2);

    vals = mean_durs(find(stims(1:end-1)==lev));
    vals = vals(~isnan(vals));
    errorbar(lev, mean(vals), std(vals)/sqrt(length(vals)), 'Color', 'blue');
    scatter(lev, median(vals), 60, 'MarkerEdgeColor', 'red', 'MarkerFaceColor', 'green', 'MarkerFaceAlpha', .2);
    %scatter(repmat(lev, 1, length(vals)), vals, 25, 'MarkerEdgeColor', 'blue',...
    %'MarkerEdgeAlpha',.3);
end
yyaxis right
plot(stats.psy(:,1), stats.psy(:,2), 'k+--');
ylabel('Percent Hit')
xlabel('Stimulus Strength')
left_color = [1 1 1];
right_color = [1 1 1];
set(gcf,'defaultAxesColorOrder',[left_color; right_color]);

hold off;

%% without outliers
stims_with_bad_removed = stims;
%stims_with_bad_removed(find(dont_use==1)) = -10;
stim_levels = unique(stims);
figure; hold on;
medians = [];
for i = 1:length(stim_levels)
    lev = stim_levels(i);
    %disp([int2str(lev) ':   ' int2str(length(find(stims_with_bad_removed==lev)))])
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
        sensitivityFactor = 3; % Whatever you want.
        thresholdValue = sensitivityFactor * mad;
        outlierIndexes = abs(absoluteDeviation) > thresholdValue;
        %disp(length(find(outlierIndexes==1)))
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
