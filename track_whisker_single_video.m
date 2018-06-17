function [centroids, good_frames] = track_whisker_single_video(FileTif, bg, do_display, detail_timing, do_save)
    catchDelta = 75;
    sensitivity_base = .15;
    tic
    %% load tiff
    %FinalImage=ScanImageTiffReader(FileTif).data;
    InfoImage=imfinfo(FileTif); mImage=InfoImage(1).Width;
    nImage=InfoImage(1).Height; NumberImages=length(InfoImage);
    FinalImage=zeros(nImage,mImage,NumberImages,'uint16');
    for i=1:NumberImages
       FinalImage(:,:,i)=imread(FileTif,'Index',i);
    end
    
    if detail_timing; disp('tiff load'); toc; tic; end
    
    %% convert and scale all the images - possibly unnecessary
    nu = single(FinalImage);
    nu = nu - min(nu(:));
    nu = nu./max(nu(:));
    bg = mean(cat(3,mean(nu,3), bg),3);

    if detail_timing; disp('preprocess'); toc; tic; end

    %% variable to store centroids in
    centroids = zeros(2, size(FinalImage,3));
    good_frames = zeros(1, size(FinalImage,3));
    %% set up the blob and drawing fxn
    blob = vision.BlobAnalysis(...
           'BoundingBoxOutputPort', true, ...
           'MinimumBlobAreaSource', 'Property', 'MinimumBlobArea', 20, 'MaximumBlobArea', 5000, 'MaximumCount', 10,...
       'ExcludeBorderBlobs',false);
    blob_strict = vision.BlobAnalysis(...
           'BoundingBoxOutputPort', true, ...
           'MinimumBlobAreaSource', 'Property', 'MinimumBlobArea', 100, 'MaximumBlobArea', 5000, 'MaximumCount', 10,...
       'ExcludeBorderBlobs',true);
    %for speed, precalculate this strel thing
    disk_rad_1 = strel('disk',1,8);
    disk_rad_4 = strel('disk',2,8);
    %% first get the starting blob.
    %If not found in first frame, keep searching till it is found
    found_first = false;
    search_frame=1;
    missed = 0;
    
    while ~found_first
        if search_frame > size(nu,3)
            disp('no blobs found in video')
            break %leave the while loop
        end
        processed = process(nu(50:end-50,50:end-50, search_frame), bg(50:end-50,50:end-50));
      
        
        cleaned=imopen(threshed+1,disk_rad_2);
        threshed=binarize(processed, sensitivity_base);
        sensitivity = sensitivity_base;
        cleaned=clean(threshed+1, disk_rad_1, disk_rad_4);
        %handle differences btwn matlab 2016 and 2017
        try
            [area, centroid, bbox] = blob_strict(logical(cleaned));
        catch
            [area, centroid, bbox] = step(blob_strict,logical(cleaned));
        end
        while isempty(area) && sensitivity < .95
            sensitivity=sensitivity+.05;
            threshed=binarize(processed,sensitivity);
            cleaned=clean(threshed+1, disk_rad_1, disk_rad_4);
            %handle differences btwn matlab 2016 and 2017
            try
                [area, centroid, bbox] = blob_strict(logical(cleaned));
            catch
                [area, centroid, bbox] = step(blob_strict,logical(cleaned));
            end
            %imagesc(threshed)
            %pause(.1)
        end
        %set the new sensitivity to be just below the sensitivity that worked
        sensitivity_base = sensitivity-.05;
        if ~isempty(area)
            if length(area)>1
                %for the first one only
                %if the difference in area is less than 100, take the leftmost
                if abs(area(1)-area(2)) < 100 || (max(area)>2000)
                    [val, ind] = min(centroid(:,1));
                else
                    %take the blob with the max area
                    [val, ind] = max(area);
                end
                bbox = bbox(ind,:);
                centroid = centroid(ind,:);
            end
            centroids(:,search_frame) = centroid.';
            good_frames(search_frame)=1;
            found_first = true; %mark that we found the first centroid
        end
            if do_display
                subplot(2,3,1)
                imagesc(rerange)
                subplot(2,3,2)
                %imagesc(reranged);
                subplot(2,3,3);
                imagesc(processed);
                subplot(2,3,4);
                imagesc(threshed);
                subplot(2,3,5)
                imagesc(cleaned);
                subplot(2,3,6)
                imagesc(nu(50:end-50,50:end-50,search_frame));
                title(int2str(search_frame));
                colormap('gray')
                pause(.5)
            end
        search_frame = search_frame+1;
    end
    disp(['it took ' int2str(search_frame-1) ' frames to find a start']);
    if detail_timing; disp('first blob'); toc; tic; end
    %skip the rest if you didn't find any blobs
    %if ~found_first; continue; end
    
    %% search for remaining blobs
    for i=search_frame:size(nu,3)
        if isempty(bbox) %if missed a frame, use the previous one
            bbox = prevBB;
        end
        prevBB= bbox;
        
        %get pixels to search in
        pixX=bbox(1)-catchDelta:bbox(1)+bbox(3)+catchDelta;
        pixY=bbox(2)-catchDelta:bbox(2)+bbox(4)+catchDelta;
        %make sure it fits in the image
        pixX(pixX<1)=[]; pixY(pixY<1)=[];
        pixX(pixX>size(nu,2))=[]; pixY(pixY>size(nu,1))=[];
        processed = process(nu(pixY,pixX,i), bg(pixY,pixX));
        
        threshed=binarize(processed, sensitivity_base);
        cleaned=clean(threshed+1, disk_rad_1, disk_rad_4);
        try
            [area, centroid, bbox] = blob(logical(cleaned));
        catch
            [area, centroid, bbox] = step(blob,logical(cleaned));
        end
        sensitivity = sensitivity_base;

        while isempty(area) && sensitivity < .95
            sensitivity=sensitivity+.05;
            threshed=binarize(processed, sensitivity);
            cleaned=clean(threshed+1, disk_rad_1, disk_rad_4);
            %handle differences btwn matlab 2016 and 2017
            try
                [area, centroid, bbox] = blob_strict(logical(cleaned));
            catch
                [area, centroid, bbox] = step(blob_strict,logical(cleaned));
            end
        end
        
        if ~isempty(bbox)
            %take the blob with the max area
            [val, ind] = max(area);
            bbox = bbox(ind,:);
            centroid = centroid(ind,:);
            centroid = centroid.';
            good_frames(i) = 1;
        else
            missed = missed+1;
        end
        
        %make the bounding box and centroid pixels the actual image pixels
        if ~isempty(bbox)
            bbox(1)=bbox(1)+pixX(1)-1;
            bbox(2)=bbox(2)+pixY(1)-1;
            centroid(1) = centroid(1)+pixX(1)-1;
            centroid(2) = centroid(2)+pixY(1)-1;
            centroids(:,i) = centroid.';
        end
        if do_display
            subplot(2,3,1)
                imagesc(rerange)
                subplot(2,3,2)
                %imagesc(reranged);
                subplot(2,3,3);
                imagesc(processed);
                subplot(2,3,4);
                imagesc(threshed);
                subplot(2,3,5)
                imagesc(cleaned);
                if ~isempty(bbox)
                    hold on; scatter(centroid(1), centroid(2)); hold off;
                end
                subplot(2,3,6)
                imagesc(nu(:,:,i));
                if ~isempty(bbox)
                    hold on;
                    scatter([bbox(1) bbox(1)+bbox(3)], [bbox(2) bbox(2)+bbox(4)]);
                    scatter(centroid(1), centroid(2));
                    hold off;
                end
            title(int2str(i));
            colormap('gray')
            pause(.05)
        end
    end
    if detail_timing; disp('other blobs'); toc; end
    if do_save
    save(strrep(FileTif, '.tif', '_tracked_data.mat'), 'centroids', 'good_frames');
    end
    disp([int2str(missed) ' missed frames'])
    disp(['finished ' FileTif])
    toc
    
end

function processed = process(crop_im, crop_bg)
    rerange = crop_im-crop_bg;
    rerange = rerange-min(rerange(:));
    rerange = rerange./max(rerange(:));
    processed = imgaussfilt(rerange,2); %denoise
end


function threshed=binarize(processed, sensitivity)
    %threshed=-imbinarize(processed, sensitivity*mean(processed(:)));

    threshed=-imbinarize(processed, 'adaptive', 'Sensitivity',sensitivity, 'ForegroundPolarity', 'dark');
end

function cleaned = clean(im, disk_erode, disk_close)
    cleaned = imerode(im, disk_erode);
    cleaned = imclose(cleaned, disk_close);
end

