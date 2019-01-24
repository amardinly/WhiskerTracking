function WhiskerImaging2

% Initialize Saving
gd.Internal.save.path = strcat('E:\Alan\',datestr(now,'yymmdd'));
gd.Internal.save.base = '0000_000_000';
gd.Internal.save.index = sprintf('%04d',1);
gd.Internal.save.filename = '';

% Initialize Imaging
inputs = {...
    'Brightness','',9.5625;...
    'Gain','Manual',6.823;...
    'Shutter','Manual',0.8};
%     'FrameRate','Manual',230;...
%     'Sharpness','Manual',1024;...
%     'Gamma','Manual',1;...
%     'Exposure','Manual',0.8287;... % exposure doesn't do anything for the flea3
gd.Internal.imaging.UDPport = 55000;

% Display parameters
Display.units = 'pixels';
Display.position = [300, 200, 1200, 700];


%% Generate GUI

% Create figure
gd.gui.fig = figure(...
    'NumberTitle',          'off',...
    'Name',                 'Whisker Imaging',...
    'Units',                Display.units,...
    'Position',             Display.position,...
    'ToolBar',              'none',...
    'MenuBar',              'none');

% Create panels
gd.gui.file.panel = uipanel(...
    'Title',                'File Information',...
    'Parent',               gd.gui.fig,...
    'Units',                'Normalized',...
    'Position',             [0, .7, .2, .3]);
gd.gui.control.panel = uipanel(...
    'Title',                'Controls',...
    'Parent',               gd.gui.fig,...
    'Units',                'Normalized',...
    'Position',             [0, 0, .2, .7]);
gd.gui.axes.panel = uipanel(...
    'Title',                'Video',...
    'Parent',               gd.gui.fig,...
    'Units',                'Normalized',...
    'Position',             [.2, .25, .8, .75]);
gd.gui.sliders.panel = uipanel(...
    'Title',                'Settings',...
    'Parent',               gd.gui.fig,...
    'Units',                'Normalized',...
    'Position',             [.2, 0, .8, .25]);

% Create file selection
% select directory
gd.gui.file.dir = uicontrol(...
    'Style',                'pushbutton',...
    'String',               'Dir',...
    'Parent',               gd.gui.file.panel,...
    'Units',                'normalized',...
    'Position',             [0,.25,.3,.25],...
    'Callback',             @(hObject,eventdata)ChooseDir(hObject, eventdata, guidata(hObject)));
% basename input
gd.gui.file.base = uicontrol(...
    'Style',                'edit',...
    'String',               gd.Internal.save.base,...
    'Parent',               gd.gui.file.panel,...
    'Units',                'normalized',...
    'Position',             [.3,.25,.5,.25],...
    'Callback',             @(hObject,eventdata)CreateFilename(guidata(hObject)));
% file index
gd.gui.file.index = uicontrol(...
    'Style',                'edit',...
    'String',               num2str(gd.Internal.save.index),...
    'Parent',               gd.gui.file.panel,...
    'Units',                'normalized',...
    'Position',             [.8,.25,.2,.25],...
    'Callback',             @(hObject,eventdata)CreateFilename(guidata(hObject)));
% mouse name
gd.gui.file.mousename = uicontrol(...
    'Style',                'edit',...
    'String',               'mmmm',...
    'Parent',               gd.gui.file.panel,...
    'Units',                'normalized',...
    'Position',             [0,.5,.3,.25],...
    'Callback',             @(hObject,eventdata)CreateFilepath(guidata(hObject)));

gd.gui.file.isonline = uicontrol(...
    'Style',                'togglebutton',...
    'String',               'Is Online',...
    'Parent',               gd.gui.file.panel,...
    'Units',                'normalized',...
    'Position',             [.4,.5,.3,.25],...
    'Callback',             @(hObject,eventdata)CreateFilepath(guidata(hObject)));

% % display filename
gd.gui.file.filename = uicontrol(...
    'Style',                'text',...
    'String',               '',...
    'Parent',               gd.gui.file.panel,...
    'Units',                'normalized',...
    'Position',             [0,0,1,.2]);

% Create controls
% preview control
gd.gui.control.preview = uicontrol(...
    'Style',                'togglebutton',...
    'String',               'Preview',...
    'Parent',               gd.gui.control.panel,...
    'Units',                'normalized',...
    'Position',             [0,.8,1,.2],...
    'Callback',             @(hObject,eventdata)PreviewImages(hObject, eventdata, guidata(hObject)));
% snap control
gd.gui.control.stream = uicontrol(...
    'Style',                'togglebutton',...
    'String',               'Slow Stream',...
    'Parent',               gd.gui.control.panel,...
    'Units',                'normalized',...
    'Position',             [0,.6,1,.2],...
    'Callback',             @(hObject,eventdata)SlowStream(hObject, eventdata, guidata(hObject)));
% trigger control
gd.gui.control.trigger = uicontrol(...
    'Style',                'togglebutton',...
    'String',               'Trigger: External',...
    'Parent',               gd.gui.control.panel,...
    'Units',                'normalized',...
    'Position',             [0,.45,1,.1],...
    'Callback',             @(hObject,eventdata)ChangeSource(hObject, eventdata, guidata(hObject)));
% new file toggle
gd.gui.control.logging = uicontrol(...
    'Style',                'togglebutton',...
    'String',               'Save to: Disk',...
    'Parent',               gd.gui.control.panel,...
    'Units',                'normalized',...
    'Position',             [0,.35,1,.1],...
    'Callback',             @(hObject,eventdata)ChangeLogging(hObject, eventdata, guidata(hObject)));
% frames per trigger
gd.gui.control.frameRate = uicontrol(...
    'Style',                'edit',...
    'String',               '300',...
    'Parent',               gd.gui.control.panel,...
    'Units',                'normalized',...
    'Position',             [.8,.25,.2,.1],...
    'Callback',             @(hObject,eventdata)ChangeFrameRate(hObject, eventdata, guidata(hObject)));
gd.gui.control.frameRateText = uicontrol(...
    'Style',                'text',...
    'String',               'Frame Rate (Hz):',...
    'Parent',               gd.gui.control.panel,...
    'Units',                'normalized',...
    'Position',             [.3,.275,.49,.05],...
    'HorizontalAlignment',  'right');
% file type
gd.gui.control.fileType = uicontrol(...
    'Style',                'togglebutton',...
    'String',               '.tif',...
    'Parent',               gd.gui.control.panel,...
    'Units',                'normalized',...
    'Position',             [0,.25,.3,.1],...
    'UserData',             {'.tif','.avi'},...
    'Callback',             @(hObject,eventdata)set(hObject,'String',hObject.UserData{hObject.Value+1}));
% image control
gd.gui.control.run = uicontrol(...
    'Style',                'togglebutton',...
    'String',               'Capture Images?',...
    'Parent',               gd.gui.control.panel,...
    'Units',                'normalized',...
    'Position',             [0,0,1,.2],...
    'BackgroundColor',      [0,1,0],...
    'Callback',             @(hObject,eventdata)CaptureImages(hObject, eventdata, guidata(hObject)));

% Create Axes
% axes
gd.gui.axes.axes = axes(...
    'Parent',               gd.gui.axes.panel,...
    'Units',                'normalized',...
    'Position',             [.2,0,.8,1]);
axis square off
% format selector
gd.gui.axes.format = uicontrol(...
    'Style',                'popupmenu',...
    'String',               {'1280x960','640x512'},...
    'Value',                2,...
    'Parent',               gd.gui.axes.panel,...
    'Units',                'normalized',...
    'Position',             [0,.9,.2,.1],...
    'Callback',             @(hObject,eventdata)initCamera(guidata(hObject)));
% frames acquired counter
gd.gui.axes.acqCounter = uicontrol(...
    'Style',                'text',...
    'String',               'Frames Acquired: 0',...
    'Parent',               gd.gui.axes.panel,...
    'Units',                'normalized',...
    'Position',             [0,.8,.2,.1],...
    'HorizontalAlignment',  'right');
% frames acquired counter
gd.gui.axes.saveCounter = uicontrol(...
    'Style',                'text',...
    'String',               'Frames Saved: 0',...
    'Parent',               gd.gui.axes.panel,...
    'Units',                'normalized',...
    'Position',             [0,.75,.2,.1],...
    'HorizontalAlignment',  'right');
% test frame rate
gd.gui.axes.testFrameRate = uicontrol(...
    'Style',                'pushbutton',...
    'String',               'Test Frame Rate',...
    'Parent',               gd.gui.axes.panel,...
    'Units',                'normalized',...
    'Position',             [0,.1,.2,.1],...
    'Callback',             @(hObject,eventdata)TestFrameRate(hObject, eventdata, guidata(hObject)));
% frame rate text
gd.gui.axes.FrameRate = uicontrol(...
    'Style',                'text',...
    'String',               'frame rate: ',...
    'Parent',               gd.gui.axes.panel,...
    'Units',                'normalized',...
    'Position',             [0,.025,.2,.05],...
    'HorizontalAlignment',  'left');

% Settings
gd.Internal.settings.modes = {'Off','Manual','Auto'};
% inputs
gd.Internal.settings.num = size(inputs,1);
gd.Internal.settings.handles = [];
h = 1/gd.Internal.settings.num;
for index = 1:gd.Internal.settings.num
    b = (gd.Internal.settings.num-index)*h;
    gd.gui.sliders.text.(inputs{index,1}) = uicontrol(...
        'Style',                'text',...
        'String',               sprintf('%s',inputs{index,1}),...
        'Parent',               gd.gui.sliders.panel,...
        'Units',                'normalized',...
        'Position',             [0,b,.1,h],...
        'HorizontalAlignment',  'right');
    gd.gui.sliders.input.(inputs{index,1}) = uicontrol(...
        'Style',                'edit',...
        'String',               sprintf('%.3f',1),...
        'Parent',               gd.gui.sliders.panel,...
        'Units',                'normalized',...
        'Position',             [.1,b,.1,h],...
        'UserData',             [inputs(index,1),{1},{0},{2}],...
        'Callback',             @(hObject,eventdata)EditSetting(hObject, eventdata, guidata(hObject)));
    gd.gui.sliders.(inputs{index,1}) = uicontrol(...
        'Style',                'slider',...
        'Parent',               gd.gui.sliders.panel,...
        'Units',                'normalized',...
        'Position',             [.2,b,.7,h],...
        'UserData',             inputs{index,1},...
        'Min',                  0,...
        'Max',                  2,...
        'Value',                1,...
        'Callback',             @(hObject,eventdata)ChangeSetting(hObject, eventdata, guidata(hObject)));
    gd.Internal.settings.handles = [gd.Internal.settings.handles,gd.gui.sliders.(inputs{index,1})];
    val = find(strcmp(gd.Internal.settings.modes,inputs{index,2}));
    if ~isempty(val)
        gd.gui.sliders.state.(inputs{index,1}) = uicontrol(...
            'Style',                'popupmenu',...
            'String',               gd.Internal.settings.modes,...
            'Parent',               gd.gui.sliders.panel,...
            'Units',                'normalized',...
            'UserData',             inputs{index,1},...
            'Position',             [.9,b,.1,h],...
            'Value',                val,...
            'Callback',             @(hObject,eventdata)ToggleAuto(hObject, eventdata, guidata(hObject)));
            gd.Internal.settings.handles = [gd.Internal.settings.handles,gd.gui.sliders.state.(inputs{index,1})];
    else
        gd.gui.sliders.state.(inputs{index,1}) = [];
    end
end
gd.Internal.settings.inputs = inputs;

gd = CreateFilename(gd);
try
    gd = initCamera(gd);
catch ME
    error('Problem connecting to camera -> try ''imaqreset'' (may need to open FlyCap2 and set camera to Mode 0)');
end
guidata(gd.gui.fig,gd);
end


%% File Saving
function ChooseDir(hObject, eventdata, gd)
temp = uigetdir(gd.Internal.save.path, 'Choose directory to save to');
if ischar(temp)
    gd.Internal.save.path = temp;
    guidata(hObject, gd);
end
gd=CreateFilename(gd);
guidata(hObject,gd);
end

function gd=CreateFilename(gd)
gd.Internal.save.filename = fullfile(gd.Internal.save.path, sprintf('%s_%04d%s', gd.gui.file.base.String, str2double(gd.gui.file.index.String), gd.gui.control.fileType.String));
gd.gui.file.filename.String = gd.Internal.save.filename;
if exist(gd.Internal.save.filename, 'file')
    gd.gui.file.filename.BackgroundColor = [1,0,0];
else
    gd.gui.file.filename.BackgroundColor = [.94,.94,.94];
end
guidata(gd.gui.fig,gd);
end

function gd = CreateFilepath(gd)
if gd.gui.file.isonline.Value
    gd.Internal.save.path = strcat('E:\Alan\',datestr(now,'yymmdd'),'_', gd.gui.file.mousename.String, '_online\');
else
    gd.Internal.save.path = strcat('E:\Alan\',datestr(now,'yymmdd'),'_', gd.gui.file.mousename.String);
end
gd=CreateFilename(gd);
end


%% Initialization
function gd = initCamera(gd)
if isfield(gd,'vid')
    delete(gd.vid);
end
% if gd.gui.axes.format.Value == 1
%     gd.vid = videoinput('pointgrey', 1, 'F7_Raw8_640x512_Mode0'); % not binned
% elseif gd.gui.axes.format.Value == 2
gd.vid = videoinput('pointgrey', 1, 'F7_Raw8_640x512_Mode1');
% end
gd.src = getselectedsource(gd.vid);
gd.vid.ReturnedColorspace = 'grayscale';

% Set camera settings
for index = 1:gd.Internal.settings.num
    
    str = gd.Internal.settings.inputs{index,1};
    val = gd.Internal.settings.inputs{index,3};
    
    % Set limits
    temp = propinfo(gd.src,str);                            % determine limits
    gd.gui.sliders.(str).Min = temp.ConstraintValue(1);     % set lower bound
    gd.gui.sliders.(str).Max = temp.ConstraintValue(2);     % set upper bound
    gd.gui.sliders.input.(str).UserData{3} = temp.ConstraintValue(1);
    gd.gui.sliders.input.(str).UserData{4} = temp.ConstraintValue(2);
    
    % Set mode
    if ~isempty(gd.gui.sliders.state.(str))
        gd.src.(sprintf('%sMode',str)) = gd.Internal.settings.modes{gd.gui.sliders.state.(str).Value}; % set mode
    end
    
    % Set value
    if val<temp.ConstraintValue(1)      % ensure value is above lower bound
        val = temp.ConstraintValue(1);
    elseif val>temp.ConstraintValue(2)  % ensure value is below upper bound
        val = temp.ConstraintValue(2);
    end
    gd.src.(str) = val;                 % set value
    gd.gui.sliders.(str).Value = val;   % update gui slider
    gd.gui.sliders.input.(str).String = sprintf('%.3f',val); % update gui text
    
end
gd.src.TriggerDelayMode = 'Off'; %'Off' or 'Manual'
% gd.src.TriggerDelay = 0;

% Create out pulses
gd.src.Strobe2 = 'On';
gd.src.Strobe2Polarity = 'High';

% Set logging mode
gd.vid.LoggingMode = 'memory';  % set logging mode
gd.vid.DiskLogger = [];         % upate disklogger field

warning('off','imaq:pointgrey:setDeprecatedProperty');
guidata(gd.gui.fig,gd);
end


%% Change controls
function ChangeSource(hObject, eventdata, gd)
if hObject.Value
    set(hObject,'String','Trigger: Internal','BackgroundColor',[0,0,0],'ForegroundColor',[1,1,1]);
else
    set(hObject,'String','Trigger: External','BackgroundColor',[.94,.94,.94],'ForegroundColor',[0,0,0]);
end
end

function ChangeLogging(hObject, eventdata, gd)
if hObject.Value
    set(hObject,'String','Save to: Memory','BackgroundColor',[0,0,0],'ForegroundColor',[1,1,1]);
    set(gd.gui.control.frameRate,'Enable','off');
else
    set(hObject,'String','Save to: Disk','BackgroundColor',[.94,.94,.94],'ForegroundColor',[0,0,0]);
    set(gd.gui.control.frameRate,'Enable','on');
end
end

function ChangeFrameRate(hObject, eventdata, gd)
num = str2double(hObject.String);
if isnan(num) || num < 1
    hObject.String = 300;
end
end


%% Change settings
function ChangeSetting(hObject, eventdata, gd)
gd.src.(hObject.UserData) = hObject.Value; % set camera value
gd.gui.sliders.input.(hObject.UserData).String = sprintf('%.3f',hObject.Value); % update value shown on gui
gd.gui.sliders.input.(hObject.UserData).UserData{2} = hObject.Value;            % update memory of value
end

function EditSetting(hObject, eventdata, gd)
value = str2double(hObject.String);
if isnan(value)                     % not a number
    hObject.String = sprintf('%.3f',hObject.UserData{2}); % return to previous value
    return
elseif value < hObject.UserData{3}  % below lower bound
    value = hObject.UserData{3};
    hObject.String = string(value);
elseif value > hObject.UserData{4}  % above upper bound
    value = hObject.UserData{4};    
    hObject.String = string(value);
end
gd.src.(hObject.UserData{1}) = value;               % set value
hObject.UserData{2} = value;                        % update memory of value
gd.gui.sliders.(hObject.UserData{1}).Value = value; % update gui slider
end

function ToggleAuto(hObject, eventdata, gd)
try
    mode = gd.Internal.settings.modes{hObject.Value};   % determine mode
    gd.src.(sprintf('%sMode',hObject.UserData)) = mode; % set mode
    if ismember(mode,{'Off','Auto'})                    % update whether slider is enabled
        gd.gui.sliders.(hObject.UserData).Enable = 'off';
    else
        gd.gui.sliders.(hObject.UserData).Enable = 'on';
    end
catch
    hObject.Value = 1;
    mode = gd.Internal.settings.modes{hObject.Value};
    gd.src.(sprintf('%sMode',hObject.UserData)) = mode;
end
end

function gd = TestFrameRate(hObject, eventdata, gd)
hObject.String = 'Testing...';
triggerconfig(gd.vid, 'immediate'); % set trigger type
gd.vid.TriggerRepeat = 0;           % set number of trigger repetitions
gd.vid.FramesPerTrigger = 100;      % set number of frames to capture
gd.vid.LoggingMode = 'memory';      % set to log frames to memory
start(gd.vid);                      % start acquisition
wait(gd.vid,120);                   % wait for acquisition to stop
[f,t,m] = getdata(gd.vid);          % acquire timestamps
frameRate = 1/mean(diff(t));        % calculate framerate
hObject.String = 'Test Frame Rate';
gd.gui.axes.FrameRate.String = sprintf('frame rate: %.2f', frameRate); % display frame rate
end

%% Imaging
function SlowStream(hObject, eventdata, gd)
if hObject.Value
    hObject.String='Stop Stream';
    set([gd.gui.control.preview,gd.gui.control.run],'Enable','off');
    numFrames = round(gd.src.FrameRate/8); % set amount of frames to show in each loop
    triggerconfig(gd.vid, 'immediate'); % internal trigger
    gd.vid.FramesPerTrigger = Inf;
    start(gd.vid);                  % start imaging
    while hObject.Value             % check if user stopped acquisition
        if gd.vid.FramesAvailable >= numFrames
            data = getdata(gd.vid,gd.vid.FramesAvailable);           % gather all available frames
            size(data)
            for index = max(size(data,4)-numFrames+1,1):size(data,4) % display only most recent frames
                imagesc(gd.gui.axes.axes,data(:,:,1,index));         % display next frame
                colormap gray
                axis square off
                pause(0.05);                                         % pause to set frame rate of playback
                if ~hObject.Value
                    break
                end
            end
        end
    end
    stop(gd.vid); % stop imaging
    set([gd.gui.control.preview,gd.gui.control.run],'Enable','on');
    hObject.String='Slow Stream';
end
end


function PreviewImages(hObject, eventdata, gd)
if hObject.Value
    set([gd.gui.control.stream,gd.gui.control.run],'Enable','off');
    axes(gd.gui.axes.axes);
    hImage = image(zeros(gd.vid.VideoResolution));
    preview(gd.vid, hImage);
    axis square off
    hObject.String = 'Stop Preview';
else
    stoppreview(gd.vid);
    hObject.String = 'Preview';
    set([gd.gui.control.stream,gd.gui.control.run],'Enable','on');
end
% frame = getsnapshot(gd.vid);
% axes(gd.gui.axes.axes);
% imagesc(frame); 
% colormap gray; axis square off
end


function CaptureImages(hObject, eventdata, gd)
if hObject.Value
    try
        % Update GUI
        set(hObject,'String','Stop','BackgroundColor',[1,0,0]);
        set([gd.gui.file.dir,gd.gui.file.base,gd.gui.file.index],'Enable','off');
        set([gd.gui.control.stream,gd.gui.control.trigger,gd.gui.control.logging,gd.gui.axes.format],'Enable','off');
        set(gd.Internal.settings.handles,'Enable','off');
        
        % Set trigger properties
        if gd.gui.control.trigger.Value % internal trigger
            triggerconfig(gd.vid, 'immediate');
            gd.vid.FramesPerTrigger = Inf;
            gd.vid.TriggerRepeat = 0;
        else
            triggerconfig(gd.vid, 'hardware', 'risingEdge', 'externalTriggerMode0-Source0'); % external trigger
            gd.vid.FramesPerTrigger = 1;
            gd.vid.TriggerRepeat = inf;
%             triggerconfig(vid, 'hardware', 'risingEdge', 'externalTriggerMode15-Source0'); % trig N
%             gd.src.TriggerParameter = 255; % # of frames per trigger in Mode15 (max: 255)
        end
        
        % Reset camera and frame counter
        flushdata(gd.vid);
        gd.gui.axes.acqCounter.String = 'Frames Acquired: 0';
        gd.gui.axes.saveCounter.String = 'Frames Saved: 0';
        
        % Set where to display images
        axes(gd.gui.axes.axes);
        hImage = image(zeros(gd.vid.VideoResolution));
        preview(gd.vid, hImage);
        axis square off
            
        % Create file and start recording
        if gd.gui.control.logging.Value % save frames to memory
            start(gd.vid);                  % start imaging
            while hObject.Value             % wait for user to stop acquisition
                pause(.5);
                gd.gui.axes.acqCounter.String = sprintf('Frames Acquired: %d',gd.vid.FramesAcquired);
            end
            stop(gd.vid);                   % stop imaging
            gd.gui.axes.acqCounter.String = sprintf('Frames Acquired: %d',gd.vid.FramesAcquired);
            if gd.vid.FramesAcquired > 0
                data = getdata(gd.vid,gd.vid.FramesAvailable); % gather frames
                viewImgs(data);             % display frames
            end
            
        else % save frames to disk
            warning('off','MATLAB:audiovideo:VideoWriter:noFramesWritten'); % final file will get opened and closed w/o data, then deleted
                        
            % Create first trial's filename
            gd.gui.file.index.String = '1';
            gd = CreateFilename(gd);
            Ext = gd.Internal.save.filename(end-3:end);
            if strcmp(Ext,'.tif')
                meta.Photometric = Tiff.Photometric.MinIsBlack;
                meta.ImageLength = 512;
                meta.ImageWidth = 640;
                meta.RowsPerStrip = 640;
                meta.BitsPerSample = 8;
                meta.Compression = Tiff.Compression.None;
                meta.SampleFormat = Tiff.SampleFormat.UInt;
                meta.SamplesPerPixel = 1;
                meta.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
            end
            
            % Open file trigger
            u = udp('localhost','LocalPort',gd.Internal.imaging.UDPport); % set file trigger port
            try
                fopen(u);           % open connection
            catch                   % connection already exists
                fclose(instrfind);  % close all connections
                fopen(u);           % retry opening connection
            end
            
            % Start imaging
            gd.vid.LoggingMode = 'memory';  % set logging mode
            start(gd.vid);                  % start imaging
            
            % Start saving incoming data
            filecounter = 1;
            framecounter = 0;
            frameRate = str2double(gd.gui.control.frameRate.String);
            while hObject.Value
                %Hayley edit: create directory if not available
                if ~exist(gd.Internal.save.path, 'dir')
                    mkdir(gd.Internal.save.path);
                end
                % Create file
                if strcmp(Ext,'.avi')
                    FILE = VideoWriter(gd.Internal.save.filename, 'Grayscale AVI'); % initialize file to save to
                    FILE.FrameRate = frameRate;                                     % set frame rate
                    open(FILE);                                                     % open file to save to
                else
                    FILE = Tiff(gd.Internal.save.filename, 'w');
                    FILE.setTag(meta);
                end
                
                % Wait for file trigger
                while hObject.Value && ~u.BytesAvailable % wait for file trigger or user to quit
                    pause(.01); % free up commmand line 
                    gd.gui.axes.acqCounter.String = sprintf('Frames Acquired: %d',gd.vid.FramesAcquired); % record 
                end

                if gd.vid.FramesAvailable~=0 % frames received
                    
                    % Save acquired frames to file
                    N = gd.vid.FramesAvailable;
                    fprintf('Finished %d: %d frames ',filecounter,N);
                    [data,t,m] = getdata(gd.vid,N); % gather frames
                    if strcmp(Ext,'.avi')
                        for index = 1:N
                            writeVideo(FILE,data(:,:,1,index));
                        end
                    else
                        FILE.write(data(:,:,1,1));
                        for index = 2:N
                            FILE.writeDirectory();
                            FILE.setTag(meta);
                            FILE.write(data(:,:,1,index))
                        end
                    end
                    save([gd.Internal.save.filename(1:end-3),'mat'],'t','m');
                    framecounter = framecounter+N;
                    gd.gui.axes.saveCounter.String = sprintf('Frames Saved: %d',framecounter);
                    close(FILE);
                    fprintf('saved to: %s\n',gd.Internal.save.filename);
                    
                    % Set next file's filename
                    if u.BytesAvailable % received file trigger
                        str = str2double(fgetl(u));
                    else                % user quit and frames were acquired
                        str = str2double(gd.gui.file.index.String)+1;
                    end
                    filecounter = filecounter + 1;  % increment fprintf index
                    gd.gui.file.index.String = sprintf('%04d',str); % set file index
                    gd.Internal.save.filename = fullfile(gd.Internal.save.path, strcat(gd.gui.file.base.String, '_', gd.gui.file.index.String, Ext));

                else % no frames acquired
                    close(FILE);                        % close AVI
                    delete(gd.Internal.save.filename); % delete empty AVI
                end
            end
            stop(gd.vid);
            fclose(u);
            
            % Increment filename
            if exist(fullfile(gd.Internal.save.path,[gd.gui.file.base.String,'_1.avi']),'file')
                N = str2double(gd.gui.file.base.String(end-2:end));
                if ~isnan(N)
                    gd.gui.file.base.String = [gd.gui.file.base.String(1:end-3),sprintf('%03d',N+1)];
                end
                gd.gui.file.index.String = '1';
            end
        end
        
        stoppreview(gd.vid);
        
        % Update GUI
        guidata(hObject,gd);
        set([gd.gui.file.dir,gd.gui.file.base,gd.gui.file.index],'Enable','on');
        set([gd.gui.control.trigger,gd.gui.control.stream,gd.gui.control.logging,gd.gui.axes.format],'Enable','on');
        set(gd.Internal.settings.handles,'Enable','on');
        set(hObject,'String','Capture Images?','BackgroundColor',[0,1,0]);
        
    catch ME
        
        % Stop imaging
        try
            stop(gd.vid);
        end
        
        % Update GUI
        guidata(hObject,gd);
        set([gd.gui.file.dir,gd.gui.file.base,gd.gui.file.index],'Enable','on');
        set([gd.gui.control.trigger,gd.gui.control.stream,gd.gui.control.logging,gd.gui.axes.format],'Enable','on');
        set(gd.Internal.settings.handles,'Enable','on');
        set(hObject,'String','Capture Images?','BackgroundColor',[0,1,0],'Value',0);
        
        rethrow(ME);        
        
    end
else % user quit
    hObject.String = 'Stopping...'; % update GUI

end

end
