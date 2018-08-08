searchFolder =  '/mnt/modulation/amardinly/MagnetTracking/AlanTrackResults/AllResults/';
behaviorFolder =  '/mnt/excitation/amardinly/BehaviorData/';

trackFiles = dir([searchFolder '*.mat']);

for findex = 1:length(trackFiles)
    file = trackFiles(findex).name;
    %remove .mat from file name
    file = strrep(file, '.mat', '');
    %split the string by _ to get the animal name and the date
    splits = strsplit(file, '_');
    date = splits{1};
    month = date(3:4);
    if month(1) == '0'
        month = month(2);
    end
    day = date(5:6);
    if day(1) == '0'
        day = day(2);
    end
    name = splits{2};
    %TEMP: handle special case of my experiment
    if contains(file, '180628_8923')
        name = [splits{2} '_' splits{3}];
    end
    %now search for all suitable behavior files
    behFiles = dir([behaviorFolder name '*2018_' month '_' day '_*BoxRIG.txt']);
    if ~isempty(behFiles)
        if length(behFiles)==1
            disp([file ': ' behFiles.name])
            Trials = readBehaviorData([behaviorFolder behFiles.name]);
            behData.Trials = Trials;
            behData.stats = getBehaviorStatsMod(behData);
            behData.fname = behFiles.name;
            save([searchFolder file '.mat'], 'behData', '-append');
        else
            disp([file ': ' behFiles.name])
            traces = load([searchFolder file '.mat']);
            traces = traces.WhiskerTrace;
            behDatas = {}; disparities = nan(1,length(behFiles));
            for bindex = 1:length(behFiles)
                [Trials, start] = readIncompleteBehaviorData([behaviorFolder behFiles(bindex).name]);
                if start > 1
                    Trials = [behDatas{bindex-1}.Trials; Trials];
                end
                disparities(bindex) = abs(length(traces)-length(Trials));
                behData.Trials = Trials;
                if size(Trials,1) > 10
                    behData.stats = getBehaviorStatsMod(behData);
                end
                behData.fname = behFiles.name;
                behDatas{bindex} = behData;
            end
            [minDisp, mini] = min(disparities);
            disp(['file : ' num2str(minDisp) ' ' behFiles(mini).name]);
            behData = behDatas{mini};
             save([searchFolder file '.mat'], 'behData', '-append');
        end
    else
        disp('no file')
    end
end

%%
for findex = 1:length(trackFiles)
    file = trackFiles(findex).name;
    struct = load([searchFolder file]);
    if isfield(struct, 'behData');
    traces = data.WhiskerTrace;
    weirdFuckUpLog = struct.weirdFuckUpLog;
    stims = struct.behData.Trials(:,1);
    %guesstimate how many of these we actually want to track
    if length(stims) > length(traces)
        if contains(file,'180611_7819')
            stims = stims(2:end);
        else
        stims = stims(1:end-(length(stims)-length(traces)));
        end
    elseif length(traces) > length(stims)
        traces = traces(1:end-(length(traces)-length(stims)));
    end
    data.stims = stims;
    %for each video get velocity and displacement
    for vindex  = 1:length(traces)
        centroids = traces{vindex};
        if ~isempty(weirdFuckUpLog)
            bad_frames = find(weirdFuckUpLog(1,:)==vindex);
        end
        [gf, v, fv, mp, pp, md, pd] = ...
            get_summarized_velocity(centroids, bad_frames, 'alan');
        data.velocities_per_vid{vindex} = v;
        data.filtered_velocities{vindex} = v;
        data.good_framesy{vindex} = gf;
        data.mean_pres(vindex) = mp;

        data.peak_pres(vindex) = pp;
        data.mean_durs(vindex) = md;
        data.peak_durs(vindex) = pd;
        [good_frames, usable_pre_cents, usable_dur_cents, ...
            x_disp, y_disp, disp] = ...
            get_summarized_displacement(centroids, bad_frames, 'alan');
        data.x_disps(vindex) = x_disp;
        data.y_disps(vindex) = y_disp;
        data.disps(vindex) = disp;
    end
    %then map stims to peak and mean velocity to get summary data
    stim_levels = unique(stims);
    summary = zeros(length(stim_levels), 10);
    for sindex = 1:length(stim_levels)
        lev = stim_levels(sindex);
        relInds = find(stims==lev);
        mean_dur = mean(data.mean_durs(find(stims==lev)));
        med_mean_dur = median(data.mean_durs(find(stims==lev)));
        se_mean_dur = std(data.mean_durs(find(stims==lev)))/sqrt(length(data.mean_durs(find(stims==lev))))
        peak_dur = mean(data.peak_durs(find(stims==lev)));
        med_peak_dur = median(data.peak_durs(find(stims==lev)));
        se_peak_dur = std(data.peak_durs(find(stims==lev)))/sqrt(length(data.peak_durs(find(stims==lev))))
        mean_disp = mean(data.disps(relInds));
        se_disp = std(data.disps(relInds))/sqrt(length(data.disps(relInds)));
        med_disp = median(data.disps(relInds));
        summary(sindex, :) = [lev, mean_dur, med_mean_dur, se_mean_dur,...
            peak_dur, med_peak_dur, se_peak_dur, mean_disp, med_disp, se_disp];
    end
    summaryTab = array2table(summary,...
    'VariableNames',{'StimLevel', 'MeanofMeanVel', 'MedofMeanVel', 'SEofMeanVel',...
                    'MeanofPeakVel', 'MedofPeakVel', 'SEofPeakVel',...
                    'MeanofDisp', 'MedofDisp', 'SEofDisp'});
                
    figure(); scatter(stim_levels, summary(:,6)); hold on;
    errorbar(stim_levels, summary(:,5), summary(:,7));
    title(file); pause(.2);
    % do k means to exclude files
    velMat = zeros(length(traces), length(data.velocities_per_vid{5})-1);
    for i = 1:length(data.velocities_per_vid)
        if size(data.velocities_per_vid{i}(2:end), 2) < size(data,2)
            velMat(i, 1:size(velocities_per_vid{i}(2:end),2)) = data.velocities_per_vid{i}(2:end);
        else
            velMat(i, :) = data.velocities_per_vid{i}(2:end);
        end
    end
    zdata=zscore(velMat,[],2);
     Widx = kmeans(zdata,2);
     if find(stims(find(Widx==1))==max(stim_levels)) >find(stims(find(Widx==2))==max(stim_levels))
         good_idx = 1
     else
         good_idx=2
     end
     
    stims_with_bad_removed = stims;
    stims_with_bad_removed(find(Widx~=good_idx)) = -10;
    for i = 1:length(stim_levels)
        lev = stim_levels(i)
        %disp([int2str(lev) ':   ' int2str(length(find(stims_with_bad_removed==lev)))])
        vals = data.peak_durs(find(stims_with_bad_removed==lev)+1);
        vals = vals(~isnan(vals));
        errorbar(lev, mean(vals), std(vals)/sqrt(length(vals)), 'Color', 'black');
        scatter(lev, median(vals), 60, 'MarkerEdgeColor', 'red', 'MarkerFaceColor', 'red', 'MarkerFaceAlpha', .2);
        scatter(repmat(lev, 1, length(vals)), vals, 25, 'MarkerEdgeColor', 'blue',...
        'MarkerEdgeAlpha',.3);
    end
    hold off;

    save([search_folder file], 'data', 'summaryTab', '-append');
    end
end
   %%     
        
%%
rigFiles = dir([behaviorFolder '*BoxRIG.txt']);
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
for vindex=1:stop_pt
    res = load([search_folder tracked_files(vindex).name]);
    
    centroids = res.centroids;
    good_frames = res.good_frames;
    [gf, v, mp, pp, md, pd] = get_summarized_velocity(centroids, good_frames);
    velocities_per_vid{vindex} = v;
    good_framesy{vindex} = gf;
    mean_pres(vindex) = mp;

    peak_pres(vindex) = pp;
    mean_durs(vindex) = md;
    peak_durs(vindex) = pd;
    [good_frames, usable_pre_cents, usable_dur_cents, x_disp, y_disp, disp] = get_summarized_displacement(centroids, good_frames);
    x_disps(vindex) = x_disp;
    y_disps(vindex) = y_disp;
    disps(vindex) = disp;
end


%% now exclude ones with whisker movement prior to things
dont_use = zeros(1, length(mean_pres));
for vindex=1:length(mean_pres)
    if isnan(mean_durs)
        dont_use(vindex)=1;
    end
    if abs(mean_durs(vindex)-mean_pres(vindex)) < .2*max(mean_durs(vindex), mean_pres(vindex)) || ...
            mean_pres(vindex) - mean_durs(vindex) > .3*max(mean_durs(vindex), mean_pres(vindex))
        dont_use(vindex)=1;
    end
end
%dont_use([17,22, 23,24,25])=1;
%%
figure;
tracked_frames = zeros(1,length(good_framesy));
for vindex=1:length(velocities_per_vid)
    subplot(ceil(sqrt(length(velocities_per_vid))),ceil(sqrt(length(velocities_per_vid))),vindex);
    
    tracked_frames(vindex) = length(good_framesy{vindex});
    plot(good_framesy{vindex}(6:end),velocities_per_vid{vindex}(good_framesy{vindex}(6:end)));
    if dont_use(vindex)
        plot(good_framesy{vindex}(6:end),velocities_per_vid{vindex}(good_framesy{vindex}(6:end)), 'Color','red');
    end
    hold on;
    temp=ylim;
    plot([15 15], [0 temp(2)], 'Color', 'black')
        title(vindex);
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
    vindex = plot_order(j);
     plot(good_framesy{vindex}(6:end),velocities_per_vid{vindex}(good_framesy{vindex}(6:end)));
    if dont_use(vindex)
        plot(good_framesy{vindex}(6:end),velocities_per_vid{vindex}(good_framesy{vindex}(6:end)), 'Color','red');
    end
    temp=ylim;
    hold on; plot([15 15], [0 temp(2)], 'Color', 'black', 'LineWidth', 2)
        title(stims(vindex));
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
stims_with_bad_removed = stims(1:end-1)
stim_levels = unique(stims);
figure; hold on;
for i = 1:length(stim_levels)
    lev = stim_levels(i)
    %disp([int2str(lev) ':   ' int2str(length(find(stims_with_bad_removed==lev)))])
    vals = data.peak_durs(find(stims_with_bad_removed==lev)+1);
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
for vindex = 1:length(stim_levels)
    lev = stim_levels(vindex);
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
for vindex = 1:length(stim_levels)
    lev = stim_levels(vindex);
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
for vindex = 1:length(stim_levels)
    lev = stim_levels(vindex);
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
stim_levels = unique(stims);
stims_with_bad_removed = stims;

figure; hold on;
medians = [];
for vindex = 1:length(stim_levels)
    lev = stim_levels(vindex);
    disp([int2str(lev) ':   ' int2str(length(find(stims_with_bad_removed==lev)))])
    vals = x8923_2.disp(find(stims_with_bad_removed==lev));
    vals = vals(~isnan(vals));
    errorbar(lev, mean(vals), std(vals)/sqrt(length(vals)), 'Color', 'black');
    medians = [medians median(vals)];
    scatter(lev, median(vals), 60, 'MarkerEdgeColor', 'red', 'MarkerFaceColor', 'red', 'MarkerFaceAlpha', .2);
    scatter(repmat(lev, 1, length(vals)), vals, 25, 'MarkerEdgeColor', 'blue',...
    'MarkerEdgeAlpha',.3);
end
plot(stats.psy(:,1), stats.psy(:,2)*max(medians), 'k+--');
hold off;

%% plot some specific stim level to investigate quality
figure;
tracked_frames = zeros(1,length(good_framesy));
sel_stims = find(stims2==75);
for j=1:length(sel_stims)
    subplot(ceil(sqrt(length(sel_stims))),ceil(sqrt(length(sel_stims))),j);
    vindex = sel_stims(j)
    tracked_frames(vindex) = length(good_framesy{vindex});
    plot(good_framesy{vindex}(6:end),velocities_per_vid{vindex}(good_framesy{vindex}(6:end)));
    if dont_use(vindex)
        plot(good_framesy{vindex}(6:end),velocities_per_vid{vindex}(good_framesy{vindex}(6:end)), 'Color','red');
    end
    hold on;
    temp=ylim;
    plot([15 15], [0 temp(2)], 'Color', 'black')
        title(vindex);
end
%%
figure;
sel_stims = find(stims2==100);
for j=1:length(sel_stims)
    subplot(ceil(sqrt(length(sel_stims))),ceil(sqrt(length(sel_stims))),j);
    vindex = sel_stims(j)
    plot(x8923_2.usable_dur_cents{vindex}(2,:), -x8923_2.usable_dur_cents{vindex}(1,:));
    hold on;
    plot(x8923_2.usable_pre_cents{vindex}(2,:), -x8923_2.usable_pre_cents{vindex}(1,:));
    daspect([1 1 1])
    
    hold off;
        title(vindex);
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
