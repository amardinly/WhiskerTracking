function [good_frames, velocities, mean_pre, peak_pre, mean_dur, peak_dur] = get_summarized_velocity(centroids, good_frames, track_type)
if isempty(track_type)
    track_type = 'hayley';
end
if strcmp(track_type, 'alan')
    centroids = centroids.';
    bad_frames = good_frames;
    
    good_frames = ones(1, size(centroids,2));
    good_frames(bad_frames) = 0;
end
good_frames = find(good_frames==1);
velocities = nan(1, size(centroids,2));
filt_cent = sgolayfilt(centroids.',3,5);
filt_cent = filt_cent.';
for j=2:length(good_frames)
    the_frame = good_frames(j);
    prev_frame = good_frames(j-1);
    distance = sqrt((filt_cent(1, the_frame)-filt_cent(1, prev_frame))^2 + ...
        (filt_cent(2, the_frame)-filt_cent(2, prev_frame))^2);
    vel = distance/(the_frame-prev_frame);
    velocities(the_frame) = vel;
end
usable_pre = good_frames(good_frames < 15 & good_frames > 5);
usable_dur = good_frames(good_frames < 45 & good_frames > 17);
mean_pre = mean(velocities(usable_pre));
peak_pre = max(velocities(usable_pre));
if isempty(usable_pre) || length(usable_pre) < 3
    mean_pre = NaN;
    peak_pre = NaN;
end
mean_dur = mean(velocities(usable_dur));
peak_dur = max(velocities(usable_dur));
if isempty(usable_dur) || length(usable_dur) < 5
    mean_dur = NaN;
    peak_dur = NaN;
end
