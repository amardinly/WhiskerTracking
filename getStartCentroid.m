function centroid = getStartCentroid(FileTif)
    %FinalImage=ScanImageTiffReader(FileTif).data;
    im=imread(FileTif);
    figure();  imagesc(im);
        disp('pick starting location');
        
        centroid = ginput(1);
        close;