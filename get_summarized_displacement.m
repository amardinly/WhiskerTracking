function [good_frames, usable_pre_cents, usable_dur_cents, x_disp, y_disp, disp] = get_summarized_displacement(centroids, good_frames, track_type)
if isempty(track_type)
    track_type = 'hayley';
end
if strcmp(track_type, 'alan')
    centroids = centroids.';
    bad_frames = good_frames;
    
    good_frames = ones(1, size(centroids,2));
    good_frames(bad_frames) = 0;
end

    filt_cent = sgolayfilt(centroids.',3,5);
    filt_cent = filt_cent.';
    good_frames = find(good_frames==1);
    
    usable_pre = good_frames(good_frames <= 17 & good_frames > 10);
    usable_dur = good_frames(good_frames < 45 & good_frames > 17);
    usable_pre_cents = filt_cent(:, usable_pre);
    usable_dur_cents = filt_cent(:, usable_dur);
    if ~isempty(usable_pre) && ~isempty(usable_dur)
    y_disp = filt_cent(1, max(usable_pre)) - max(filt_cent(1, usable_dur));
    x_disp = filt_cent(2, max(usable_pre)) - max(filt_cent(2, usable_dur));
    disp = sqrt((filt_cent(1, max(usable_pre)) - max(filt_cent(1, usable_dur)))^2 ...
        + (filt_cent(2, max(usable_pre)) - max(filt_cent(2, usable_dur)))^2);
    else
        y_disp = NaN; x_disp = NaN; disp=NaN;
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