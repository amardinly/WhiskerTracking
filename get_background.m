function bg = get_background(FileTif)
    %FinalImage=ScanImageTiffReader(FileTif).data;
    InfoImage=imfinfo(FileTif); mImage=InfoImage(1).Width;
    nImage=InfoImage(1).Height; NumberImages=length(InfoImage);
    FinalImage=zeros(nImage,mImage,NumberImages,'uint16');
    for i=1:NumberImages
       FinalImage(:,:,i)=imread(FileTif,'Index',i);
    end
    
    %% convert and scale all the images - possibly unnecessary
    nu= FinalImage - min(FinalImage(:));
    nu= single(nu);
    nu = nu./max(nu(:));
    bg= imopen(mean(nu,3),strel('disk',30,8));
    bg=imgaussfilt(bg,3);
    