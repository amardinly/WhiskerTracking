search_folder =  'E:\Alan\180615_8923\';
%struct = load(['E:\Alan\180614_9122\180614_A.mat']);
%struct = load(['Z:\holography\Data\hayley\expstruct\180612_7819_calib.mat']);
%struct = struct.ExpStruct;
% stims_strings = struct.InitialStimList;
% stims = zeros(1, length(stims_strings));
% for i=1:length(stims_strings)
%     
%     temp = stims_strings{i};
%     stims(i) = str2double(temp);
% end
%stims = struct.StimulusData;

beh_file = dir([search_folder '*BoxRIG.txt']);%'9122_2018_6_14_14_32_BoxRIG.txt';
beh_file = beh_file.name
%beh_file = '9122_2018_6_15_10_55_BoxRIG.txt'%'8923_2018_6_15_11_55_BoxRIG.txt'; %'8923_2018_6_14_15_39_BoxRIG.txt';
%beh_file2 = '9122_2018_6_15_11_32_BoxRIG.txt'%'8923_2018_6_15_11_55_BoxRIG.txt'; %'8923_2018_6_14_15_39_BoxRIG.txt';

Trials = readBehaviorData([search_folder beh_file]);
%Trials2 = readBehaviorDataIncomplete([search_folder beh_file2]);
%Trials = [Trials1; Trials2];
dataOut.Trials = Trials;
stats = getBehaviorStats(dataOut);
length(Trials)
tracked_files = dir([search_folder '*_tracked_data.mat']);
length(tracked_files)
%%
stims2 = Trials(1:end,1);
%do tracked files -1 bc it seems to have an extra
stop_pt = length(tracked_files)
length_things = length(tracked_files)
%%

tracked_files = dir([search_folder '*_tracked_data.mat']);
mean_pres = zeros(1, length_things);
peak_pres = zeros(1, length_things);
mean_durs = zeros(1, length_things);
peak_durs = zeros(1, length_things);
disps = zeros(1, length_things);
x_disps = zeros(1, length_things);
y_disps = zeros(1, length_things);

velocities_per_vid = {};
good_framesy = {};
for i=1:stop_pt
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
    [good_frames, usable_pre_cents, usable_dur_cents, x_disp, y_disp, disp] = get_summarized_displacement(centroids, good_frames);
    x_disps(i) = x_disp;
    y_disps(i) = y_disp;
    disps(i) = disp;
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
%dont_use([17,22, 23,24,25])=1;
%%
figure;
tracked_frames = zeros(1,length(good_framesy));
for i=1:length(velocities_per_vid)
    subplot(ceil(sqrt(length(velocities_per_vid))),ceil(sqrt(length(velocities_per_vid))),i);
    
    tracked_frames(i) = length(good_framesy{i});
    plot(good_framesy{i}(6:end),velocities_per_vid{i}(good_framesy{i}(6:end)));
    if dont_use(i)
        plot(good_framesy{i}(6:end),velocities_per_vid{i}(good_framesy{i}(6:end)), 'Color','red');
    end
    hold on;
    temp=ylim;
    plot([15 15], [0 temp(2)], 'Color', 'black')
        title(i);
end

%%
stim_levels = unique(stims2);
plot_order = [];
for lev=stim_levels
    plot_order = [plot_order find(stims2 == lev)];
end

%%
figure;
ax=[];
for j=1:length(velocities_per_vid)
    subplot(10,10,j);
    ax = [ax gca];
    i = plot_order(j);
     plot(good_framesy{i}(6:end),velocities_per_vid{i}(good_framesy{i}(6:end)));
    if dont_use(i)
        plot(good_framesy{i}(6:end),velocities_per_vid{i}(good_framesy{i}(6:end)), 'Color','red');
    end
    temp=ylim;
    hold on; plot([15 15], [0 temp(2)], 'Color', 'black', 'LineWidth', 2)
        title(stims(i));
%         if mod(j,10) ~= 1
%         set(gca,'Yticklabel',[]) 
% set(gca,'Xticklabel',[]) %to just get rid of the numbers but leave the ticks.
%         end
end
% linkaxes(ax, 'xy')
%%

% stims(find(stims==39)) = 38;
% stims(find(stims==51)) = 38;
% stims(find(stims==38)) = 43;
% 
% stims(find(stims==90)) = 89;
% stims(find(stims==102)) = 89;
% stims(find(stims==89)) = 100;
% 
% stims(find(stims==178)) = 179;
% stims(find(stims==181)) = 179;
% stims(find(stims==229)) = 230;

stims_with_bad_removed = stims;
stims_with_bad_removed(find(dont_use==1)-1) = -10;
stim_levels = unique(stims);
figure; hold on;
length(peak_durs)
for lev = stim_levels
    disp([int2str(lev) ':   ' int2str(length(find(stims_with_bad_removed==lev)))])
    vals = peak_durs(find(stims_with_bad_removed==lev)+1);
    vals = vals(~isnan(vals));
    errorbar(lev, mean(vals), std(vals)/sqrt(length(vals)), 'Color', 'black');
    scatter(lev, median(vals), 60, 'MarkerEdgeColor', 'red', 'MarkerFaceColor', 'red', 'MarkerFaceAlpha', .2);
    scatter(repmat(lev, 1, length(vals)), vals, 25, 'MarkerEdgeColor', 'blue',...
    'MarkerEdgeAlpha',.3);
end
hold off;


%% plot of behavioral data
stims_with_bad_removed = stims2;
stims_with_bad_removed(find(dont_use==1)) = -10;
stim_levels = unique(stims2);
figure; hold on;
medians = [];
for i = 1:length(stim_levels)
    lev = stim_levels(i);
    disp([int2str(lev) ':   ' int2str(length(find(stims_with_bad_removed==lev)))])
    vals = peak_durs(find(stims_with_bad_removed==lev));
    vals = vals(~isnan(vals));
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

%% plot of behavioral data without outliers
stims_with_bad_removed = stims2;
%stims_with_bad_removed(find(dont_use==1)) = -10;
stim_levels = unique(stims2);
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

%% plot of behavioral data subtracting off mean pre
stims_with_bad_removed = stims2;
stims_with_bad_removed(find(dont_use==1)) = -10;
stim_levels = unique(stims2);
figure; hold on;
medians = [];
for i = 1:length(stim_levels)
    lev = stim_levels(i);
    disp([int2str(lev) ':   ' int2str(length(find(stims_with_bad_removed==lev)))])
    vals = mean_durs(find(stims_with_bad_removed==lev))-mean_pres(find(stims_with_bad_removed==lev));
    vals = vals(~isnan(vals));
    errorbar(lev, mean(vals), std(vals)/sqrt(length(vals)), 'Color', 'black');
    medians = [medians median(vals)];
    scatter(lev, median(vals), 60, 'MarkerEdgeColor', 'red', 'MarkerFaceColor', 'red', 'MarkerFaceAlpha', .2);
    %scatter(repmat(lev, 1, length(vals)), vals, 25, 'MarkerEdgeColor', 'blue',...
    %'MarkerEdgeAlpha',.3);
end
plot(stats.psy(:,1), stats.psy(:,2)*max(medians), 'k+--');
hold off;


%% plot of behavioral data with displacement
stims_with_bad_removed = stims2;
stims_with_bad_removed(find(dont_use==1)) = -10;
stim_levels = unique(stims2);
figure; hold on;
medians = [];
for i = 1:length(stim_levels)
    lev = stim_levels(i);
    disp([int2str(lev) ':   ' int2str(length(find(stims_with_bad_removed==lev)))])
    vals = x8923_2.disp(find(stims_with_bad_removed==lev));
    vals = vals(~isnan(vals));
    errorbar(lev, mean(vals), std(vals)/sqrt(length(vals)), 'Color', 'black');
    medians = [medians median(vals)];
    scatter(lev, median(vals), 60, 'MarkerEdgeColor', 'red', 'MarkerFaceColor', 'red', 'MarkerFaceAlpha', .2);
    %scatter(repmat(lev, 1, length(vals)), vals, 25, 'MarkerEdgeColor', 'blue',...
    %'MarkerEdgeAlpha',.3);
end
plot(stats.psy(:,1), stats.psy(:,2)*max(medians), 'k+--');
hold off;

%% plot some specific stim level to investigate quality
figure;
tracked_frames = zeros(1,length(good_framesy));
sel_stims = find(stims2==75);
for j=1:length(sel_stims)
    subplot(ceil(sqrt(length(sel_stims))),ceil(sqrt(length(sel_stims))),j);
    i = sel_stims(j)
    tracked_frames(i) = length(good_framesy{i});
    plot(good_framesy{i}(6:end),velocities_per_vid{i}(good_framesy{i}(6:end)));
    if dont_use(i)
        plot(good_framesy{i}(6:end),velocities_per_vid{i}(good_framesy{i}(6:end)), 'Color','red');
    end
    hold on;
    temp=ylim;
    plot([15 15], [0 temp(2)], 'Color', 'black')
        title(i);
end
%%
figure;
sel_stims = find(stims2==100);
for j=1:length(sel_stims)
    subplot(ceil(sqrt(length(sel_stims))),ceil(sqrt(length(sel_stims))),j);
    i = sel_stims(j)
    plot(x8923_2.usable_dur_cents{i}(2,:), -x8923_2.usable_dur_cents{i}(1,:));
    hold on;
    plot(x8923_2.usable_pre_cents{i}(2,:), -x8923_2.usable_pre_cents{i}(1,:));
    daspect([1 1 1])
    
    hold off;
        title(i);
end

%%
% % % % % 
% x8923_15.mean_durs = mean_durs;
% x8923_15.peak_durs = peak_durs;
% x8923_15.mean_pres = mean_pres;
% x8923_15.peak_pres = peak_pres;
% x8923_15.stims = stims2;
% x8923_15.dont_use = dont_use;
% x8923_15.stats = stats;
% x8923_15.Trials=Trials;

x9122_13.disps = disps;
