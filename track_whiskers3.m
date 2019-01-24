function track_whiskers3(folder, varargin)

p = inputParser;
addParameter(p,'display',0);
addParameter(p,'startCentroid',[]);
   
addParameter(p,'catchDelta',150);
   
addParameter(p,'divineIntervention',0);
   
addParameter(p,'debug',0);
   
addParameter(p,'saveName','AlanTrackResults');
addParameter(p,'saveFolder',folder);

parse(p,varargin{:});
settings = p.Results;
startCentroid = settings.startCentroid;
catchDelta = settings.catchDelta;
record = 0;

%precalculate all structuring elements for speed
diskRad10 = strel('disk',10,8);
diskRad25 = strel('disk',25,8);

files = dir([folder '*.tif']);
%make background the mean of8 random videos
randints = randi(length(files), 1, 8);
InfoImage=imfinfo([folder files(1).name]);
bg = zeros(InfoImage(1).Height, InfoImage(1).Width, 8);
for index = 1:length(randints)
    i = randints(index);
    if i == 1 && isempty(startCentroid)
        figure();  imagesc(ImgData(:,:,1));
        disp('pick starting location');
        
        lastCentroid = ginput(1);
        close;
        %     BB=[0 0 0 0];
        StartpixX= round(lastCentroid(1)-catchDelta:lastCentroid(1)+catchDelta);
        StartpixY = round(lastCentroid(2)-catchDelta:lastCentroid(2)+catchDelta);
        startCentroid = lastCentroid;
    end
    FileTif=[folder files(i).name];
    InfoImage=imfinfo(FileTif); mImage=InfoImage(1).Width;
    nImage=InfoImage(1).Height; NumberImages=length(InfoImage);
    FinalImage=zeros(nImage,mImage,NumberImages,'uint16');
    for j=1:NumberImages
       FinalImage(:,:,j)=imread(FileTif,'Index',j);
    end
    %ImgData=permute(ImgData,[2 1 3]);
    ImgData=single(FinalImage);
   
    bg(:,:,index) = imopen(mean(ImgData,3),diskRad10);
end
lastCentroid = startCentroid;
StartpixX= round(lastCentroid(1)-catchDelta:lastCentroid(1)+catchDelta);
StartpixY = round(lastCentroid(2)-catchDelta:lastCentroid(2)+catchDelta);

weirdFuckUpLogs = cell(1, int16(length(files)));
WhiskerTrace = cell(1, int16(length(files)));
nogoM = zeros(size(bg,1), size(bg,2));
nogoM(15:end-15, 15:end-15)=1;
nogoM = ~nogoM;

mean_background = mean(bg(:,:,:),3);

for i  = 1:6%1:numel(files);
    tic
   
    if record;
        vw=VideoWriter([settings.saveFolder settings.saveName ' ' num2str(i) '.avi'],'Uncompressed AVI');
        open(vw);
    end
    
    %clear position;
    %ImgData=ScanImageTiffReader([path D(Tiffindx(i)).name]).data;
    FileTif=[folder files(i).name];
    InfoImage=imfinfo(FileTif); mImage=InfoImage(1).Width;
    nImage=InfoImage(1).Height; NumberImages=length(InfoImage);
    FinalImage=zeros(nImage,mImage,NumberImages,'uint16');
    for j=1:NumberImages
       FinalImage(:,:,j)=imread(FileTif,'Index',j);
    end
    %ImgData=permute(ImgData,[2 1 3]);
    disp('finished loading tiff'); toc;
    ImgData=single(FinalImage);
       
    pixX = StartpixX;
    pixY = StartpixY;
    lastCentroid = startCentroid;

    pixX(pixX<1)=[];
    pixY(pixY<1)=[];
    pixX(pixX>size(ImgData,2))=[];
    pixY(pixY>size(ImgData,1))=[];
    
    %create the tracking variables
    position = zeros(size(ImgData,3), 2);
    Fi = 1; weirdFuckUpLog = [];
    
    %join the background between this one and the general purpose one
    t_bg = zeros(size(ImgData,1), size(ImgData,2), 2);
    t_bg(:,:,1) = mean_background;
    t_bg(:,:,2) = imopen(mean(ImgData,3),diskRad10);
    for iv=1:size(ImgData,3);
        
        
        exitFlag=0;
        
        I = ImgData(:,:,iv);
        I2=imgaussfilt(I,2);
         
        
        I3 = I2 - background;
        I3 = abs(I3-max(I3(:)));
        I4=I3(pixY,pixX);
        
        lightground = imopen(I4,diskRad25);%20
        
        I4=I4-lightground;
        
        
        I5=imgaussfilt(I4,7);%10
        %remove adjust artifacts
        k =3;
        bw = imbinarize(I5,k*mean(I5(:)));
        centroid =[10000 10000];   %always trigger first run
        expand=0;
        
        while (max(bw(:))==0  ||   sqrt(((centroid(1)-lastCentroid(1))^2) + ((centroid(2)-lastCentroid(2))^2))>catchDelta) && ~exitFlag;
            
            if max(bw(:))==0;
                bw = imbinarize(I5,k*mean(I5(:)));
                k=k-.25;
            elseif expand && sqrt(((centroid(1)-lastCentroid(1))^2) + ((centroid(2)-lastCentroid(2))^2))>catchDelta
                bw = imbinarize(I5,k*mean(I5(:)));
                k=k-.25;
                expand = 0;
            elseif sqrt(((centroid(1)-lastCentroid(1))^2) + ((centroid(2)-lastCentroid(2))^2))>catchDelta 
                
                kk=bwconncomp(bw,8);
                rp=regionprops(kk);
                numPixels = cellfun(@numel,kk.PixelIdxList);
                [biggest,idx] = sort(numPixels,'descend');
                for W = 1:numel(idx);
                    centroid = rp(idx(W)).Centroid;
                    centroid = centroid + [pixX(1) pixY(1)];
                    BB=rp(idx(W)).BoundingBox;
                    BB=round(BB);
                    if sqrt(((centroid(1)-lastCentroid(1))^2) + ((centroid(2)-lastCentroid(2))^2))<catchDelta;
                        %                             disp('Found Correct Centroid');
                        exitFlag=1;
                        break;
                    elseif iv == 1;
                        %                             disp('First Frame');
                        exitFlag=1;
                        break;
                    end
                end
                expand = 1;
                
                
                
            end;
        end;
        
        
        
        BB(1)=BB(1)+pixX(1);
        BB(2)=BB(2)+pixY(1);
        
        pixX=BB(1)-catchDelta:BB(1)+BB(3)+catchDelta;
        pixY=BB(2)-catchDelta:BB(2)+BB(4)+catchDelta;
        
        pixX(pixX<1)=[];
        pixY(pixY<1)=[];
        pixX(pixX>size(I,2))=[];
        pixY(pixY>size(I,1))=[];
        if centroid(1)>size(I,2);
            centroid(1)=size(I,2);
        end
        if centroid(2)>size(I,1);
            centroid(2)=size(I,1);
        end
        
        if iv == 1;
            lastCentroid = centroid;
        elseif (sqrt(((centroid(1)-lastCentroid(1))^2) + ((centroid(2)-lastCentroid(2))^2))>catchDelta) ==1 || nogoM(round(centroid(2)),round(centroid(1)))==1;
            weirdFuckUpLog(Fi,1)=i;
            weirdFuckUpLog(Fi,2)=iv;
            disp(['missed frame ' num2str(iv)  ' on file ' num2str(i)]);
            Fi = Fi +1;
            lastCentroid = startCentroid;
            pixX = StartpixX;
            pixY = StartpixY;
            pixX(pixX<1)=[];
            pixY(pixY<1)=[];
            pixX(pixX>size(I,2))=[];
            pixY(pixY>size(I,1))=[];
            
            
        else
            lastCentroid = centroid;
        end
        
        
        
        if settings.display;
            subplot(1,2,1)
            imagesc(I3); colormap gray; caxis([-100 300]);  axis square; axis off;
            hold on;
            scatter(centroid(1),centroid(2));
            text(20,70,['t = ' num2str(round(1000*(iv/300))) ' ms']);
            %             rectangle('position',[pixX(1) pixY(1) numel(pixX) numel(pixY)])
            %             rectangle('position',[BB(1) BB(2) BB(3) BB(4)],'EdgeColor','r')
            
            pause(0.1);
            hold off;
            subplot(1,2,2);
            hold off
            imagesc(I5);
            axis square; axis off;
            hold on
            caxis([0 20])
            if settings.debug
                waitforbuttonpress
                iv
            end
            if record
                h=getframe(fig);
                writeVideo(vw,h.cdata);
            end
        end
        
        position(iv,:)=centroid;
    end
    
    WhiskerTrace{i}=position;
    weirdFuckUpLogs{i} = weirdFuckUpLog;
    if record;
        close(vw);
    end
    disp(['Finished file ' num2str(i) ' of ' num2str(length(files))]);
    toc
end


save([settings.saveFolder settings.saveName '.mat'],'WhiskerTrace','StartpixX','StartpixY','weirdFuckUpLogs','startCentroid');

end