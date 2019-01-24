function bg = get_background_offline(search_folder)

    files = dir([search_folder '*.tif']);
    files = files(randperm(length(files), 10))
    FileTif = [search_folder files(1).name];
    InfoImage=imfinfo(FileTif); mImage=InfoImage(1).Width;
    nImage=InfoImage(1).Height;
    ims_for_bg = zeros(nImage, mImage, length(files)*5);
    for i = 1:length(files)
        FileTif = [search_folder files(i).name];
        InfoImage=imfinfo(FileTif); mImage=InfoImage(1).Width;
        nImage=InfoImage(1).Height; NumberImages=length(InfoImage);
        FinalImage=zeros(nImage,mImage,NumberImages,'uint16');
        for i=1:NumberImages
           FinalImage(:,:,i)=imread(FileTif,'Index',i);
        end
    
        %% convert and scale all the images - possibly unnecessary
        nu = FinalImage - min(FinalImage(:));
        nu = single(nu);
        nu = nu./max(nu(:));
        ims_for_bg(:,:,(i-1)*5+1:i*5) = nu(:,:,15+randperm(40,5));
    end
    bg = imopen(mean(ims_for_bg,3),strel('disk',30,8));
    bg =imgaussfilt(bg,3);