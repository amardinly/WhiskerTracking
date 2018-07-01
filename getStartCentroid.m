function centroid = getStartCentroid(FileTif)
    centroid = [];
    %FinalImage=ScanImageTiffReader(FileTif).data;
    InfoImage=imfinfo(FileTif); NumberImages=length(InfoImage);
    i=1;
    figure()
    while i < NumberImages
        im=imread(FileTif, 'Index', i);
        imagesc(im);
        i=i+25;
        [x,y,button] = ginput(1);
        if button == 1
            centroid = [x,y];
            break
        end
        i=i+25;
    end
        close;