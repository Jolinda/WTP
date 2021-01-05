function [PTBParams, runNum, study] = InitPTB(homepath)
% function [subjid ssnid datafile PTBParams] = InitPTB(homepath)
% 
% Function for initializing parameters at the beginning of a session
%
% homepath: Path name to scripts directory for the study
%
% Author: Cendri Hutcherson
% Modified by: Dani Cosme
% Last Modified: 10-06-2017

%% Housecleaning before the guests arrive
cd(homepath);
clear all; close all; Screen('CloseAll'); 
homepath = [pwd '/'];

%% Get study and subject info 
% Check to make sure aren't about to overwrite duplicate session!
checksubjid = 1;
while checksubjid == 1
    study = 'DEV'; %removed user input for convenience
    subjid = input('Subject number (3 digits):  ', 's');
    ssnid = input('Session number (1-5):  ', 's');
    if str2num(ssnid) < 3
        runid = input('Run number (1-4):  ');
    else 
        runid = input('Run number (1-2):  ');
    end
    
    if runid == 1 && (exist(fullfile(homepath, 'SubjectData', [study subjid], [study,'.',subjid,'.',ssnid,'.mat']),'file') == 2)
        cont = input('WARNING: Datafile already exists!  Overwrite? (y/n)  ','s');
        if cont == 'y'
            checksubjid = 0;
        else
            checksubjid = 1;
        end
    else
        checksubjid = 0;
    end
end   

% Set defaults for subject number and session
if isempty(subjid)
    subjid = '999';
end

if isempty(ssnid)
    ssnid = '1';
end

% Create name of datafile where data will be stored    
if ~exist([homepath 'SubjectData/' study subjid],'dir')
    mkdir([homepath 'SubjectData/' study subjid]);
end

% Specify run number to use in the data structure
runNum = sprintf('run%d',runid);
datafile = fullfile(homepath, 'SubjectData', [study subjid], [study,'.',subjid,'.',ssnid,'.mat']);

if exist(datafile,'file')
    load(datafile);
end
Data.subjid = subjid;
Data.ssnid = ssnid;
Data.(char(runNum)).time = datestr(now);

save(datafile,'Data');

%% Initialize parameters for fMRI
if str2num(ssnid) < 3
    inMRI = input('MRI session? 0 = no, 1 = yes: ');
else
    inMRI = 0;
end

% if no input, default = not in MRI
if isempty(inMRI)
    inMRI = 0;
end

% assign trigger
if inMRI == 0
    trigger = KbName('SPACE');
else
    trigger = 52;
end

%% Initialize keys 
PTBParams.keys = ButtonLoad();
%[response_keyboard, ~] = setUpDevices(inMRI);
%PTBParams.keys = initKeysFromId(response_keyboard, trigger);

%% Initialize PsychToolbox parameters and save in PTBParams struct
AssertOpenGL;
ListenChar(2); % don't print keypresses to screen
Screen('Preference', 'SkipSyncTests', 1); % use if VBL fails; use this setting on the laptop
%Screen('Preference', 'VisualDebugLevel',3);

HideCursor; %comment out for testing only

% Set screen number
screenNum=max(Screen('Screens'));
%screenNum=0;

% Set screen size and parameters
[w, rect] = Screen('OpenWindow',screenNum);
%[w, rect] = Screen('OpenWindow',screenNum, [], [0 0 800 400]); %DCos 2015.06.25, Use for debugging

ctr = [rect(3)/2, rect(4)/2]; 
white=WhiteIndex(w);
black=BlackIndex(w);
gray = (WhiteIndex(w) + BlackIndex(w))/2;
ifi = Screen('GetFlipInterval', w);


% Save parameters in PTBParams structure
PTBParams.win = w;
PTBParams.rect = rect;
PTBParams.ctr = ctr;
PTBParams.white = white;
PTBParams.black = black;
PTBParams.gray = gray;
PTBParams.ifi = ifi;
PTBParams.datafile = datafile;
PTBParams.homepath = homepath;
PTBParams.subjid = subjid;
PTBParams.ssnid = ssnid;
%PTBParams.keys = initKeys(inMRI);
PTBParams.inMRI = inMRI;
PTBParams.(char(runNum)).runid = runid;

% Save PTBParams structure
datafile = fullfile(homepath, 'SubjectData', [study subjid], ['PTBParams.',subjid,'.',ssnid,'.mat']);
save(datafile,'PTBParams');

% Flip screen
Screen(w,'TextSize',round(.1*ctr(2)));
Screen('TextFont',w,'Helvetica');
Screen('FillRect',w,black);

% Used to initialize mousetracking object, otherwise the first time
% this is called elsewhere it can take up to 300ms, throwing off timing
[tempx, tempy] = GetMouse(w);

WaitSecs(.5);
    
%% Seed random number generator 
rng(GetSecs, 'twister')

end

% no longer used
function [response_keyboard, internal_keyboard] = setUpDevices(MRI)
numDevices=PsychHID('NumDevices');
devices=PsychHID('Devices');

%makes start device the control computer (see note below re: customizing to your computer)
if MRI
    for k = 1:numDevices
        if strcmp(devices(k).usageName,'Keyboard') && strcmp(devices(k).product,'Xkeys')
            internal_keyboard=k;
            fprintf('Defaulting: Home Device is #%d (%s)\n',internal_keyboard,devices(internal_keyboard).product);
            break,
        end
    end
else
    for k = 1:numDevices
        if strcmp(devices(k).transport,'USB') && strcmp(devices(k).usageName,'Keyboard') && strcmp(devices(k).product,'Apple Internal Keyboard / Trackpad') %note: this is the name of my default device-- may need to be updated depending on your system
            internal_keyboard=k;
            fprintf('Home Device is #%d (%s)\n',internal_keyboard,devices(internal_keyboard).product);
            break,
        elseif strcmp(devices(k).transport,'Bluetooth') && strcmp(devices(k).usageName,'Keyboard')
            internal_keyboard=k;
            fprintf('Home Device is #%d (%s)\n',internal_keyboard,devices(internal_keyboard).usageName);
        elseif strcmp(devices(k).product,'Apple Internal Keyboard / Trackpad') && strcmp(devices(k).usageName,'Keyboard')
            internal_keyboard=k;
            fprintf('Home Device is #%d (%s)\n',internal_keyboard,devices(internal_keyboard).usageName);
        elseif strcmp(devices(k).manufacturer,'Apple Inc.') && strcmp(devices(k).usageName,'Keyboard')
            internal_keyboard=k;
            fprintf('Home Device is #%d (%s)\n',internal_keyboard,devices(internal_keyboard).usageName);
        end
    end
end

%if button box was requested at start of experiment, use it, otherwise, use
%the keyboard
if MRI
    for n=1:numDevices
        if strcmp(devices(n).usageName,'Keyboard') && strcmp(devices(n).product,'Xkeys')
            response_keyboard=n;
            fprintf('Using Device #%d (%s)\n',response_keyboard,devices(response_keyboard).product);
            break,
        end
    end
else
    for n=1:numDevices
        if strcmp(devices(n).transport,'Bluetooth') && strcmp(devices(n).usageName,'Keyboard')
            response_keyboard=n;
            break,
        elseif strcmp(devices(n).transport,'ADB') && strcmp(devices(n).usageName,'Keyboard')
            response_keyboard=n;
            break,
        elseif strcmp(devices(n).transport,'USB') && strcmp(devices(n).usageName,'Keyboard')
            response_keyboard=n;
            break,
        elseif strcmp(devices(n).transport,'SPI') && strcmp(devices(n).usageName,'Keyboard')
            response_keyboard=n;
        end
    end
    fprintf('Using Device #%d (%s)\n',response_keyboard,devices(n).product);
end
end

