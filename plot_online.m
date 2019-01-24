function plot_online(doUse, peak_durs, stims)
stims_with_bad_removed = stims;
stims_with_bad_removed(find(doUse==0)) = -10;
stim_levels = unique(stims);
figure(2)
for lev = stim_levels
    %disp([int2str(lev) ':   ' int2str(length(find(stims_with_bad_removed==lev)))])
    vals = peak_durs(find(stims_with_bad_removed==lev));
    vals = vals(~isnan(vals));
    errorbar(lev, mean(vals), std(vals)/sqrt(length(vals)), 'Color', 'black');hold on;

    scatter(lev, median(vals), 60, 'MarkerEdgeColor', 'red', 'MarkerFaceColor', 'red', 'MarkerFaceAlpha', .2);
    scatter(repmat(lev, 1, length(vals)), vals, 25, 'MarkerEdgeColor', 'blue',...
    'MarkerEdgeAlpha',.3);
end
hold off;