%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% File created by: Jay Kim
% Date created: 2017-08-16
% Date modified: 2017-08-30
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% ****************************************************
% 1. Change saveDir to save response data files. 
% 2. Change imageDir to where the images are saved. 
% ****************************************************


function runExp
%% Subject ID
% Copied from Julian's code
subj.number = input('Enter subject number, 01-99:\n','s'); % '99'
subj.initials = input('Enter subject initials:\n','s'); % 'JM'
subj.level = input('Enter subject experience level (1,2 or 3):\n','s') % 1-3


%% Files and directories
% Define directories; will change this later
saveDir = 'C:/Users/jayja/Documents/2017-02/Nao/Results/';
imageDir = 'C:/Users/jayja/Documents/2017-02/Nao/snapshots/';

% Read in image file names
disp('Creating trials...')
fileNames = dir(strcat(imageDir,'*.jpg')); % Need to select which night######
nFiles = length(fileNames);

% Create a random order
orderMat = [(1:nFiles)',randperm(nFiles)']; % Col1: order in file Name; Col2: order being shown


%% Window layout //Put into a separate file later //pretty much copied from Julian's code
% Window size (blank is full screen)
Exp.Cfg.WinSize_ori = get(0, 'Screensize');
Exp.Cfg.WinSize = Exp.Cfg.WinSize_ori;
Exp.Cfg.WinSize(3) = Exp.Cfg.WinSize(3)*0.95;
winHor = Exp.Cfg.WinSize(3);
winVert = Exp.Cfg.WinSize(4);

% Screen
Exp.Cfg.screens = Screen('Screens');

% Apparently (Julian) this makes things robust
if isunix
    % Exp.Cfg.screenNumber = min(Exp.Cfg.screens); % Attached monitor
    Exp.Cfg.screenNumber = max(Exp.Cfg.screens); % Main display
else
    % Exp.Cfg.screenNumber = max(Exp.Cfg.screens); % Attached monitor
    Exp.Cfg.screenNumber = min(Exp.Cfg.screens); % Main display
end

% Define colours
Exp.Cfg.Color.white = WhiteIndex(Exp.Cfg.screenNumber);
Exp.Cfg.Color.black = BlackIndex(Exp.Cfg.screenNumber);
Exp.Cfg.Color.gray = round((Exp.Cfg.Color.white + Exp.Cfg.Color.black)/2);

% Open a new window
[Exp.Cfg.win, Exp.Cfg.windowRect] = Screen('OpenWindow', ...
	Exp.Cfg.screenNumber , Exp.Cfg.Color.gray, Exp.Cfg.WinSize_ori, [], 2, 0);

% Find window size
[Exp.Cfg.width, Exp.Cfg.height] = Screen('WindowSize', Exp.Cfg.win);

% Define center X & Y
[Exp.Cfg.xCentre , Exp.Cfg.yCentre] = RectCenter(Exp.Cfg.windowRect);

% Font
Screen('TextFont', Exp.Cfg.win, 'Arial');


%% Pentagon buttons layout //put into a func
% Number of partitions within pentagon structure
nPartition = 5; % 4 confidence levels + hollow centre

% Diameter of the outer pentagon
Exp.Cfg.rs = (winHor/2)*0.95; % Outermost diameter
pentDiameter = []; % Pentagon diameters; length = nPartition
for i = 1:nPartition
    pentDiameter = [pentDiameter, Exp.Cfg.rs*((nPartition-i+1)/nPartition)];
end
pentRad = pentDiameter/2; % pentagon radii

% Pentagon position; the right half of the window
buttonOffset_x = 3*winHor/4;
buttonOffset_y = winVert/2;

% Pentagon coordinates
pentCoord_y = [];
pentCoord_x = [];
for i = 1:nPartition
    pentCoord_y = -[-pentCoord_y; pentRad(i), cos(2*pi/5)*pentRad(i), ...
        -cos(pi/5)*pentRad(i), -cos(pi/5)*pentRad(i), ...
        cos(2*pi/5)*pentRad(i), pentRad(i)];
    pentCoord_x = [pentCoord_x; 0, sin(2*pi/5)*pentRad(i), ...
        sin(4*pi/5)*pentRad(i), -sin(4*pi/5)*pentRad(i), ...
        -sin(2*pi/5)*pentRad(i), 0];
end
pentCoord_y = pentCoord_y + buttonOffset_y; % Offset to position
pentCoord_x = pentCoord_x + buttonOffset_x; % Offset to position

% Background and highlighting colours
backgroundColour = [177, 187, 217, 100]; % Background; pastel purple
lightYellow = [255,255,224,100]; % Will use later for highlighting

% Set background colour
Screen('FillRect',  Exp.Cfg.win, backgroundColour);

% Colour in the pentagons (distinguish confidence levels)
pentColour = []; % Will be used for legend
for i = 1:nPartition-1
    pentColour = [pentColour, Exp.Cfg.Color.white-(i-1)* ...
        (Exp.Cfg.Color.white-Exp.Cfg.Color.gray)/(nPartition-1)];
    Screen('FillPoly', Exp.Cfg.win, pentColour(i), ...
        horzcat(pentCoord_x(i,:)', pentCoord_y(i,:)'));
end
Screen('FillPoly', Exp.Cfg.win, backgroundColour, ...
    horzcat(pentCoord_x(nPartition,:)', pentCoord_y(nPartition,:)'));

% Legend bar for confidence level colours
legendPos_x = (Exp.Cfg.WinSize_ori(3)-Exp.Cfg.WinSize(3))*0.1+Exp.Cfg.WinSize(3);
legendPos_y = Exp.Cfg.WinSize(4)*0.1;
barLength = Exp.Cfg.WinSize(4)*0.8;
barWidth = (Exp.Cfg.WinSize_ori(3)-Exp.Cfg.WinSize(3))*0.8;
for i = 1:nPartition-1
    Screen('FillRect', Exp.Cfg.win, pentColour(nPartition-i), ...
        [legendPos_x, legendPos_y+barLength*((i-1)/(nPartition-1)), ...
        legendPos_x+barWidth, legendPos_y+barLength*(i/(nPartition-1))]);
    DrawFormattedText(Exp.Cfg.win, int2str(nPartition-i), legendPos_x+barWidth/3, ...
        legendPos_y+barLength*((i-0.3)/(nPartition-1)), [0 0 0]);
end
Screen('TextSize', Exp.Cfg.win, floor(barWidth/2));
DrawFormattedText(Exp.Cfg.win, 'Sure', legendPos_x, ...
    legendPos_y - barWidth/4, [0 0 0]);
DrawFormattedText(Exp.Cfg.win, 'Not\nsure', legendPos_x, ...
    legendPos_y + barLength + barWidth/2, [0 0 0]);

% Draw lines
lineWidth = 1;
for i = 1:5
    % Pentagon outliine
    for j = 1:nPartition
        Screen('DrawLine', Exp.Cfg.win,Exp.Cfg.Color.black, pentCoord_x(j,i), ...
            pentCoord_y(j,i), pentCoord_x(j,i+1), pentCoord_y(j,i+1), lineWidth)
    end
    
    % Lines across pentagons
    Screen('DrawLine', Exp.Cfg.win,Exp.Cfg.Color.black, pentCoord_x(1,i), ...
        pentCoord_y(1,i), pentCoord_x(nPartition,i), pentCoord_y(nPartition,i), lineWidth)
end

% Sleep class text position coordinates
sleepClassTextPos_x = [];
sleepClassTextPos_y = [];
tmp_max = 0;
tmp_min = 0;
for i = 1:5 % 5 because there are 5 classes (pentagon)
	tmp_max = max([pentCoord_x(2,i), pentCoord_x(2,i+1), ...
        pentCoord_x(nPartition,i), pentCoord_x(nPartition,i+1)]);
	tmp_min = min([pentCoord_x(2,i), pentCoord_x(2,i+1), ...
        pentCoord_x(nPartition,i), pentCoord_x(nPartition,i+1)]);
	sleepClassTextPos_x = [sleepClassTextPos_x; (tmp_max+tmp_min)/2];
	tmp_max = max([pentCoord_y(2,i), pentCoord_y(2,i+1), ...
        pentCoord_y(nPartition,i), pentCoord_y(nPartition,i+1)]);
	tmp_min = min([pentCoord_y(2,i), pentCoord_y(2,i+1), ...
        pentCoord_y(nPartition,i), pentCoord_y(nPartition,i+1)]);
	sleepClassTextPos_y = [sleepClassTextPos_y; (tmp_max+tmp_min)/2];
end

% Put sleep class text
Screen('TextSize',Exp.Cfg.win, floor(barWidth/2));
sleepClassTexts = {'Wake', 'REM', 'N1', 'N2', 'N3'}; % hard-coded
for i = 1:5 % 5 because there are 5 classes (pentagon)
	DrawFormattedText(Exp.Cfg.win, sleepClassTexts{i}, ...
		sleepClassTextPos_x(i), sleepClassTextPos_y(i), [0 0 0]);
end


%% Pentagon region divisions; which levels/classes does the click belong to?
% Confidence level mask
confidenceMask = [];
for i = 1:nPartition
    confidenceMask{i} = poly2mask(pentCoord_x(i,:), pentCoord_y(i,:), ...
        Exp.Cfg.WinSize_ori(4),Exp.Cfg.WinSize_ori(3));
end
for i = 1:nPartition-1
    confidenceMask{i} = confidenceMask{i} - confidenceMask{i+1};
end

% Sleep classification coordinates
classCoord_x = [];
classCoord_y = [];
for i = 1:5 % 5 because there are 5 classes (pentagon)
    classCoord_x = [classCoord_x; pentCoord_x(1,i), pentCoord_x(1,i+1), ...
        pentCoord_x(nPartition,i), pentCoord_x(nPartition,i+1), pentCoord_x(1,i)];
    classCoord_y = [classCoord_y; pentCoord_y(1,i), pentCoord_y(1,i+1), ...
        pentCoord_y(nPartition,i), pentCoord_y(nPartition,i+1), pentCoord_y(1,i)];
end

% Sleep class mask
classMask = [];
for i = 1:5
    classMask{i} = poly2mask(classCoord_x(i,:), classCoord_y(i,:), ...
        Exp.Cfg.WinSize_ori(4),Exp.Cfg.WinSize_ori(3));
end


%% Run the experiment
% Size of displayed image
image_rect = [0, 0, winHor/2, floor(winHor*2/6)]; % Size of object images; ratio ok??
subjectResponse = [];

for m = 1:nFiles 
    % Load the image in queue
    showImage = imread(strcat(imageDir,fileNames(orderMat(m,2)).name));
    Probe_Tex = Screen('MakeTexture', Exp.Cfg.win, showImage);

    % Image position; centre of the left half
	imageOffset_x = winHor/4;
	imageOffset_y = (winVert)/2;
    showImageProbe = CenterRectOnPoint(image_rect, imageOffset_x, imageOffset_y);
    if m==1 % From the second image, we want ot update images a bit later
        % Draw correct images to screen
        Screen('DrawTextures', Exp.Cfg.win, Probe_Tex, [], showImageProbe, 0);
    end

    % Present everything
    Screen('Flip',Exp.Cfg.win, [], 1);
    if m>1
        % Time delay
        WaitSecs(0.5);

        % Colour in the pentagons //make a pentagon layout func + call it
        pentColour = []; % Will be used for legend
        for i = 1:nPartition-1
            pentColour = [pentColour, Exp.Cfg.Color.white-(i-1)* ...
                (Exp.Cfg.Color.white-Exp.Cfg.Color.gray)/(nPartition-1)];
            Screen('FillPoly', Exp.Cfg.win, pentColour(i), ...
                horzcat(pentCoord_x(i,:)', pentCoord_y(i,:)'));
        end
        Screen('FillPoly', Exp.Cfg.win, backgroundColour, ...
            horzcat(pentCoord_x(nPartition,:)', pentCoord_y(nPartition,:)'));   
        % Draw lines
        for i = 1:5
            % Pentagon outliine
            for j = 1:nPartition
                Screen('DrawLine', Exp.Cfg.win,Exp.Cfg.Color.black, pentCoord_x(j,i), ...
                    pentCoord_y(j,i), pentCoord_x(j,i+1), pentCoord_y(j,i+1), lineWidth)
            end

            % Lines across pentagons
            Screen('DrawLine', Exp.Cfg.win,Exp.Cfg.Color.black, pentCoord_x(1,i), ...
                pentCoord_y(1,i), pentCoord_x(nPartition,i), pentCoord_y(nPartition,i), lineWidth)
        end
        % Draw correct images to screen
        Screen('DrawTextures', Exp.Cfg.win, Probe_Tex, [], showImageProbe, 0);
		% Put sleep class text
		Screen('TextSize',Exp.Cfg.win, floor(barWidth/2));
		sleepClassTexts = {'Wake', 'REM', 'N1', 'N2', 'N3'}; % hard-coded
		for i = 1:5 % 5 because there are 5 classes (pentagon)
			DrawFormattedText(Exp.Cfg.win, sleepClassTexts{i}, ...
				sleepClassTextPos_x(i), sleepClassTextPos_y(i), [0 0 0]);
		end

        % Present everything
        Screen('Flip',Exp.Cfg.win, [], 1);
    end
    
    stay = 1;
    tmpMask = [];
    confidenceLevel = 0;
    sleepClass = 0;
    while (stay)
        [click_x, click_y, buttons] = GetMouse(Exp.Cfg.win);
        if buttons(1)
            if click_x<winHor && click_y<winVert
				% Which confidence level
				for i = 1:(nPartition-1)
					if confidenceMask{i}(click_y, click_x)
						confidenceLevel = i;
						% Which sleep class
						for j = 1:5
							if classMask{j}(click_y, click_x)==1
								sleepClass = j;
								break;
							end
						end
						if sleepClass>0 % Was it clear which class was clicked?
							stay = 0;
							% Highlight the selection
							Screen('FillPoly', Exp.Cfg.win, lightYellow, ...
								[pentCoord_x(confidenceLevel,sleepClass), ...
									pentCoord_y(confidenceLevel,sleepClass); ...
									pentCoord_x(confidenceLevel,sleepClass+1), ...
									pentCoord_y(confidenceLevel,sleepClass+1); ...
									pentCoord_x(confidenceLevel+1,sleepClass+1), ...
									pentCoord_y(confidenceLevel+1,sleepClass+1); ...
									pentCoord_x(confidenceLevel+1,sleepClass), ...
									pentCoord_y(confidenceLevel+1,sleepClass)]);
							subjectResponse = [subjectResponse; ...
								orderMat(m,2), confidenceLevel, sleepClass];
                        end
						break;
					end
				end
			end
        end
    end 
end
Screen('Flip',Exp.Cfg.win, [], 1);
WaitSecs(0.5)
        % Colour in the pentagons //make a pentagon layout func + call it
        pentColour = []; % Will be used for legend
        for i = 1:nPartition-1
            pentColour = [pentColour, Exp.Cfg.Color.white-(i-1)* ...
                (Exp.Cfg.Color.white-Exp.Cfg.Color.gray)/(nPartition-1)];
            Screen('FillPoly', Exp.Cfg.win, pentColour(i), ...
                horzcat(pentCoord_x(i,:)', pentCoord_y(i,:)'));
        end
        Screen('FillPoly', Exp.Cfg.win, backgroundColour, ...
            horzcat(pentCoord_x(nPartition,:)', pentCoord_y(nPartition,:)'));   
        % Draw lines
        for i = 1:5
            % Pentagon outliine
            for j = 1:nPartition
                Screen('DrawLine', Exp.Cfg.win,Exp.Cfg.Color.black, pentCoord_x(j,i), ...
                    pentCoord_y(j,i), pentCoord_x(j,i+1), pentCoord_y(j,i+1), lineWidth)
            end

            % Lines across pentagons
            Screen('DrawLine', Exp.Cfg.win,Exp.Cfg.Color.black, pentCoord_x(1,i), ...
                pentCoord_y(1,i), pentCoord_x(nPartition,i), pentCoord_y(nPartition,i), lineWidth)
        end
        % Draw correct images to screen
        Screen('DrawTextures', Exp.Cfg.win, Probe_Tex, [], showImageProbe, 0);
		% Put sleep class text
		Screen('TextSize',Exp.Cfg.win, floor(barWidth/2));
		sleepClassTexts = {'Wake', 'REM', 'N1', 'N2', 'N3'}; % hard-coded
		for i = 1:5 % 5 because there are 5 classes (pentagon)
			DrawFormattedText(Exp.Cfg.win, sleepClassTexts{i}, ...
				sleepClassTextPos_x(i), sleepClassTextPos_y(i), [0 0 0]);
		end

        % Present everything
        Screen('Flip',Exp.Cfg.win, [], 1);

       
%% Done screen //This causes sync error on my laptop
Screen('FillRect',  Exp.Cfg.win, backgroundColour);
DrawFormattedText(Exp.Cfg.win, 'Done :)', ...
				winHor/2, winVert/2, [0 0 0]);
WaitSecs(0.5)


%% Save subject response + aux data //R for analysis
% File names of images presented
fileNamesArr = [];
for i = 1:nFiles % Store presented file names into an array
    fileNamesArr{i,1} = i;
    fileNamesArr{i,2} = fileNames(i).name;
end
save(strcat(saveDir, subj.number, '_', subj.initials, '_', ...
    subj.level, '_', 'fileNames'), 'fileNamesArr');

% Order of files presented
save(strcat(saveDir, subj.number, '_', subj.initials, '_', ...
    subj.level, '_', 'fileOrder'), 'orderMat');

% Subject response
save(strcat(saveDir, subj.number, '_', subj.initials, '_', ...
    subj.level, '_', 'responseData'), 'subjectResponse');
end
