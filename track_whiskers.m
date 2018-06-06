function track_whiskers(path, do_display, detail_timing);
%path='C:\Users\Hayley\Documents\WhiskerTracking\';

catchDelta = 150;

%gather files
tif_list = dir([path '*.tif']);

%% set up the blob and drawing fxn
blob = vision.BlobAnalysis(...
       'BoundingBoxOutputPort', true, ...
       'MinimumBlobAreaSource', 'Property', 'MinimumBlobArea', 20, 'MaximumBlobArea', 2000, 'MaximumCount', 2,...
   'ExcludeBorderBlobs',true);
blob_strict = vision.BlobAnalysis(...
       'BoundingBoxOutputPort', true, ...
       'MinimumBlobAreaSource', 'Property', 'MinimumBlobArea', 100, 'MaximumBlobArea', 2000, 'MaximumCount', 2,...
   'ExcludeBorderBlobs',true);
shapeInserter = vision.ShapeInserter('BorderColor','White');

%cell array to save the centroids for the entire video
centroids_per_vid = cell(1, length(tif_list));

if do_display; figure; end

%% loop through each video - could parallelize
for findex=1:length(tif_list)
    tic
    %% load tiff
    FileTif=[path tif_list(findex).name];
    InfoImage=imfinfo(FileTif); mImage=InfoImage(1).Width;
    nImage=InfoImage(1).Height; NumberImages=length(InfoImage);
    FinalImage=zeros(nImage,mImage,NumberImages,'uint16');
    for i=1:NumberImages
       FinalImage(:,:,i)=imread(FileTif,'Index',i);
    end
    
    if detail_timing; disp('tiff load'); toc; tic; end
    %% convert and scale all the images - possibly unnecessary
    nu= FinalImage - min(FinalImage(:));
    nu= single(nu);
    nu = nu./max(nu(:));
    
    %get the background
    bg= imopen(mean(nu,3),strel('disk',10,8));
    
    centroids = zeros(2, size(FinalImage,3));
    
    if detail_timing; disp('preprocess'); toc; tic; end
    %% first get the starting blob.
    %If not found in first frame, keep searching till it is found
    found_first = false;
    search_frame=1;
    
    while ~found_first
        if search_frame > size(nu,3)
            disp('no blobs found in video')
            skip_vid=true;
            break %leave the while loop
        end
        processed = process(nu(:,:,search_frame),bg(:,:));
        
        threshed=binarize(processed, .15);
        cleaned=imopen(threshed+1,strel('disk',2,8));
        cleaned=imopen(cleaned,strel('disk',2,8));
        [area, centroid, bbox] = blob_strict(logical(cleaned));
        if isempty(area)
            threshed=binarize(processed, .3);
            cleaned=imopen(threshed+1,strel('disk',2,8));
            cleaned=imopen(cleaned,strel('disk',2,8));
            [area, centroid, bbox] = blob_strict(logical(cleaned));
            %imagesc(threshed)
            %pause(.1)
        end
        if ~isempty(area)
            if length(area)>1
                %for the first one only
                %if the difference in area is less than 100, take the leftmost
                if abs(area(1)-area(2)) < 100
                    [val, ind] = min(centroid(:,1));
                else
                    %take the blob with the max area
                    [val, ind] = max(area);
                end
                bbox = bbox(ind,:);
                centroid = centroid(ind,:);
            end
            centroids(:,search_frame) = centroid.';
            found_first = true; %mark that we found the first centroid
            
            if do_display
                subplot(1,3,1)
                imagesc(shapeInserter(processed,bbox));
                subplot(1,3,2)
                imagesc(cleaned);
                subplot(1,3,3)
                imagesc(nu(:,:,search_frame));
                title(int2str(search_frame));
                colormap('gray')
                pause(.3)
            end
        end
        search_frame = search_frame+1;
    end
    disp(['it took ' int2str(search_frame-1) ' frames to find a start']);
    if detail_timing; disp('first blob'); toc; tic; end
    
    %skip the rest if you didn't find any blobs
    if ~found_first; continue; end
    %% now detect blobs based on prev locations
    missed=0;
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
        
        %crop, background subtract, and scale
        processed = process(nu(pixY,pixX,i),bg(pixY,pixX));
        threshed=binarize(processed, .15);
        cleaned=imopen(threshed+1,strel('disk',2,8));
        
        [area, centroid, bbox] = blob(logical(cleaned));
        if ~isempty(bbox)
            %take the blob with the max area
            [val, ind] = max(area);
            bbox = bbox(ind,:);
            centroid = centroid(ind,:);
            centroids(:,i) = centroid.';
        else
            missed = missed+1;
        end
        
        %make the bounding box pixels the actual image pixels
        if ~isempty(bbox)
            bbox(1)=bbox(1)+pixX(1)-1;
            bbox(2)=bbox(2)+pixY(1)-1;
        end
        if do_display
            subplot(1,3,1)
            imagesc(shapeInserter(processed,bbox));
            subplot(1,3,2)
            imagesc(cleaned);
            subplot(1,3,3)
            imagesc(nu(:,:,i));
            title(int2str(i));
            colormap('gray')
            pause(.05)
        end
    end
    if detail_timing; disp('other blobs'); toc; end
    disp([int2str(missed) ' missed frames'])
    disp(['file number ' int2str(findex) ' , with name ' FileTif])
    centroids_per_vid{findex}=centroids;
    toc
end

%save the output
save([path 'whisker_track.mat'], 'centroids_per_vid')
end

%% helper functions

function processed = process(crop_im, crop_bg)
    rerange = crop_im-crop_bg;
    rerange = rerange-min(rerange(:));
    rerange = rerange./max(rerange(:));
    rerange = imadjust(rerange); %enhance contrast
    processed = imgaussfilt(rerange,2); %denoise
end


function threshed=binarize(processed, sensitivity)
    threshed=-imbinarize(processed, 'adaptive', 'Sensitivity',sensitivity, 'ForegroundPolarity', 'dark');
end
