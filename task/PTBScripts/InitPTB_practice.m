function [PTBParams, runNum, study] = InitPTB_practice(homepath)
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

inMRI = input('MRI session? 0 = no, 1 = yes: ');

% if no input, default = not in MRI
if isempty(inMRI)
    inMRI = 0;
end

PTBParams.keys = ButtonLoad();

%% Initialize PsychToolbox parameters and save in PTBParams struct
AssertOpenGL;

ListenChar(2); % dont print keypresses to screen

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
PTBParams.homepath = homepath;
%PTBParams.keys = initKeys(inMRI);
PTBParams.inMRI = inMRI;

% Flip screen
Screen(w,'TextSize',round(.1*ctr(2)));
Screen('TextFont',w,'Helvetica');
Screen('FillRect',w,black);

% Used to initialize mousetracking object, otherwise the first time
% this is called elsewhere it can take up to 300ms, throwing off timing
[tempx, tempy] = GetMouse(w);

WaitSecs(.5);
    
%% Seed random number generator 
rng(GetSecs, 'twister');

end
