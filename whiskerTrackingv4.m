%% First Crack at Whisker Tracking!
clear all; clc; close all;

%settings
catchDelta=150;
display = 0;
record = 0;
divineIntervention = 0;
debug = 0;

savename = 'alan_track';
%savepath='C:\Users\Alan Mardinly\Documents\MATLAB\MagnetStimulationPaper\WhiskerData\';
%path='X:\holography\Data\Alan\WhiskerTracking\180502_9159\';
path='E:\Alan\180615_8923\'
savepath='E:\Alan\180615_8923\'
%path = 'E:\Alan\180610_9245_1\';a
%savepath=path;
Fi = 1;
fig = figure();

D=dir(path);
i=1;
for n = 1:numel(D);
    if strfind(D(n).name,'.tif');
        Tiffindx(i)=n;
        i=i+1;
    end
end;
%%
for i  = 1:numel(Tiffindx);
    tic
    i
    if record;
        vw=VideoWriter([savename ' ' num2str(i) '.avi'],'Uncompressed AVI');
        open(vw);
    end
    
    clear position;
    %ImgData=ScanImageTiffReader([path D(Tiffindx(i)).name]).data;
    FileTif=[path D(Tiffindx(i)).name];
    InfoImage=imfinfo(FileTif); mImage=InfoImage(1).Width;
    nImage=InfoImage(1).Height; NumberImages=length(InfoImage);
    FinalImage=zeros(nImage,mImage,NumberImages,'uint16');
    for j=1:NumberImages
       FinalImage(:,:,j)=imread(FileTif,'Index',j);
    end
    %ImgData=permute(ImgData,[2 1 3]);
    ImgData=single(FinalImage);
    bg(:,:,i) = imopen(mean(ImgData,3),strel('disk',10,8));
    
    
    if i == 1
        disp('hey')
        figure();  imagesc(ImgData(:,:,1));
        disp('pick starting location');
        
        lastCentroid = ginput(1);
        close;
        %     BB=[0 0 0 0];
        StartpixX= round(lastCentroid(1)-catchDelta:lastCentroid(1)+catchDelta);
        StartpixY = round(lastCentroid(2)-catchDelta:lastCentroid(2)+catchDelta);
        startCentroid = lastCentroid;
        disp('select region to look in');
        
        figure();  imagesc(mean(ImgData,3));
        nogo = impoly;
        nogoM=nogo.createMask;
        nogoM=~nogoM;
        close;
        
    end
    
    if divineIntervention && i ~=1;
        figure();  imagesc(ImgData(:,:,1));
        lastCentroid = ginput(1);
        close;
        %     BB=[0 0 0 0];
        pixX= round(lastCentroid(1)-catchDelta:lastCentroid(1)+catchDelta);
        pixY = round(lastCentroid(2)-catchDelta:lastCentroid(2)+catchDelta);
    else
        pixX = StartpixX;
        pixY = StartpixY;
        lastCentroid = startCentroid;
    end
    pixX(pixX<1)=[];
    pixY(pixY<1)=[];
    pixX(pixX>size(ImgData,2))=[];
    pixY(pixY>size(ImgData,1))=[];
    
    
    
    for iv=1:size(ImgData,3);
        
        
        exitFlag=0;
        
        
        I = ImgData(:,:,iv);
        I2=imgaussfilt(I,2);
        
        %add cumultive background?
        if i<4;
            background = min(bg,[],3);
        else
            background = min(bg(:,:,i-3:i),[],3);
        end
        
        I3 = I2 - background;
        %         I3(nogoM)=0;
        I3 = abs(I3-max(I3(:)));
        %         I4a=imgradient(I3);
        I4=I3(pixY,pixX);
        
        lightground = imopen(I4,strel('disk',25,8));%20
        %        lightground = imopen(I4,strel('rectangle',[25 25]));%20
        
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
        elseif (sqrt(((centroid(1)-lastCentroid(1))^2) + ((centroid(2)-lastCentroid(2))^2))>catchDelta) || nogoM(round(centroid(2)),round(centroid(1)))==1;
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
        
        
        
        if display;
            subplot(1,2,1)
            imagesc(I3); colormap gray; caxis([-100 300]);  axis square; axis off;
            hold on;
            scatter(centroid(1),centroid(2));
            text(20,70,['t = ' num2str(round(1000*(iv/300))) ' ms']);
            %             rectangle('position',[pixX(1) pixY(1) numel(pixX) numel(pixY)])
            %             rectangle('position',[BB(1) BB(2) BB(3) BB(4)],'EdgeColor','r')
            
            pause(0.001);
            hold off;
            subplot(1,2,2);
            hold off
            imagesc(I5);
            axis square; axis off;
            hold on
            caxis([0 20])
            if debug
                waitforbuttonpress
                iv
            end
            if record
                h=getframe(fig);
                writeVideo(vw,h.cdata);
            end
        end
        
        position(iv,:)=centroid;
    end;
    
    WhiskerTrace{i}=position;
    if record;
        close(vw);
    end
    disp(['Finished file ' num2str(i) ' of ' num2str(numel(Tiffindx))]);
    toc
end;




save([savepath savename '.mat'],'WhiskerTrace','StartpixX','StartpixY','weirdFuckUpLog','nogoM','startCentroid');


%% camera calibration
pt1=[130 248];
pt2=[127 193];
D=sqrt(((pt1(1)-pt2(1))^2)+((pt1(2)-pt2(2))^2));
pixels_per_mm = D/(10);
FPS = 300;
%% Review Traces
usefulTraces=nan(size(WhiskerTrace,2),1);
imgFrames = find(ExpStruct.motorTrigger);
Ti=imgFrames(1):imgFrames(end);
Ti = Ti/10;
Ti = round(Ti);
%%  load('180415_D.mat');
for i = 1:size(WhiskerTrace,2)
    position=WhiskerTrace{i};
    
    
    
    filtP = sgolayfilt(position,3,5);
    
    fail=find(weirdFuckUpLog(:,1)==i);
    failFrames = weirdFuckUpLog(fail,2);
    failFrames = unique(failFrames);
    
    
    
    dF=diff(filtP);
    dF_mm = dF / pixels_per_mm;
    dF_m = dF_mm / 1000;
    Vmps = dF_m * FPS;
    Vmps = sgolayfilt(Vmps,3,5);
    Vmps(failFrames,:)=nan;
    
    plot([1:size(Vmps,1)]/FPS,Vmps);
    ylim([-3 3])
    xlabel('Seconds');
    ylabel('Velocity');
    hold on;
    plot((Ti-Ti(1))/2000,(ExpStruct.stims{i+1}{1}(Ti)/3.3)-2,'k')
    %   plot((Vmps(:,1)+Vmps(:,2)))
    hold off
    
    a=ExpStruct.stims{i+1}{1}(Ti);
    max(a)
%     b=diff(a);
%     c=find(b>0);
%     c=c/1000;
    
    waitforbuttonpress
%     Hz = 1/((mean(diff(c))))
   usefulTraces(i)=input('1 or 2');
    
end

 save([savepath savename '.mat'],'usefulTraces','-append');

analyzeDeflection(WhiskerTrace,2,48:60,sweeps,ExpStruct,usefulTraces,weirdFuckUpLog,pixels_per_mm);

%% TURN THIS INTO ITS OWN ANALYSIS SCRIPT!!!!! DUMbass
% clear MagVal;
% startSweep =2;
% 
% sweepsToUse=startSweep:numel(sweeps);
% for i = 1:numel(sweepsToUse);
%     MagVal(i)=max(ExpStruct.stims{sweepsToUse(i)}{1});
% end
% 
% 
% analysisWindow = 48:58;
% 
% umv=unique(MagVal);
% for j=1:numel(umv);
%     clear SummaryData;
% 
%     theSweeps=find(MagVal==umv(j));
% %     theSweeps  = theSweeps-startSweep+1;
%     theSweeps(theSweeps<1)=[];
%     theSweeps = theSweeps(find(usefulTraces(theSweeps)==1));
%     for k = 1:numel(theSweeps);
%         data=WhiskerTrace{theSweeps(k)};
%         filtP = sgolayfilt(data,3,5);        
%         fail=find(weirdFuckUpLog(:,1)==i);
%         failFrames = weirdFuckUpLog(fail,2);
%         failFrames = unique(failFrames);
%         
%         
%         dF=diff(filtP);
%         dF_mm = dF / pixels_per_mm;
%         dF_m = dF_mm / 1000;
%         Vmps = dF_m * FPS;
%         Vmps = sgolayfilt(Vmps,3,5);
% %         Vmps(failFrames,:)=nan;
%         
% %        Vel=dotproduct(Vmps);
%          Vel=sqrt((Vmps(:,1).^2)+(Vmps(:,2).^2));
% %          plot(Vmps);
% %          waitforbuttonpress;
%         SummaryData(k,1:size(Vel,1))=Vel;
%     end
%     meanV(j)=mean(max(SummaryData(:,analysisWindow),[],2));
%     sV(j)=stderr(max(SummaryData(:,analysisWindow),[],2));
%     
%     subplot(1,numel(umv),j);
%     fillPlot(SummaryData,[1:size(SummaryData,2)]/300,'ci'); xlabel('Seconds');
%     
%     Summary{j}=SummaryData;
% end
% figure();
% errorbar(umv,meanV,sV);
% xlabel('Volts');
% ylabel('Angular Velocity (m/s)');
% %%
% 
% 
% analysisWindow = 40:50;
% 
% umv=unique(MagVal);
% for j=1:numel(umv);
%     theSweeps=find(MagVal==umv(j));
%     for k = 1:numel(theSweeps);
%         data=WhiskerTrace{theSweeps(k)};
%         dF_mm = data / pixels_per_mm;
%         bl=mean(dF_mm(1:20,:));
%         dF_mm = sgolayfilt(dF_mm,3,5);
%         dist= sqrt(  ((dF_mm(:,1)-bl(1)).^2) +  ((dF_mm(:,2)-bl(2)).^2) );
%         
%         displacement(:,1) = ((dF_mm(:,1)-bl(1)));
%         displacement(:,2) = ((dF_mm(:,2)-bl(2)));
%         
%         
%         SummaryData(k,:)=dist;
%         SumDx(k,:)=displacement(:,1);
%         SumDz(k,:)=displacement(:,2);
%         
%         
%     end
%     meanDisp(j)=mean(mean(SummaryData(:,analysisWindow)));
%     meanDx(j)=mean(mean(SumDx(:,analysisWindow)));
%     meanDz(j)=mean(mean(SumDz(:,analysisWindow)));
%     
%     sDisp(j)=stderr(mean(SummaryData(:,analysisWindow)));
%     sDx(j)=stderr(mean(SumDx(:,analysisWindow)));
%     sDz(j)=stderr(mean(SumDz(:,analysisWindow)));
%     
%     
%     subplot(1,numel(umv),j);
%     fillPlot(SumDz,[1:size(SummaryData,2)]/300,'ci'); xlabel('Seconds');
%     
% end
% 
% figure();
% errorbar(umv,meanDisp,sDisp)
% hold on
% errorbar(umv,meanDx,sDx)
% errorbar(umv,meanDz,sDz)
