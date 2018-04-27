% This is the experiment program for gambling task on human brain. This
% project is conducted by Ruyuan Zhang (RZ). Ben Hayden and Ruyuan Zhang conceptualize and
% design the experiment.
%
% Some of the experiment paramteres are derived from the paper
%
% History:
%   20180425 RZ created it.


clear all;close all;clc;

sp.subj = input('Input the subj number: \n ');
sp.runnum = input('Input the run number: \n ');

addpath(genpath('./utils'));
%% debug purpose
sp.wantframefiles = 0;
sp.frameduration = 60;  % 120 monitor refresh, that is one second / frame.
%mp = getmonitorparams('uminn7tpsboldscreen');
mp = getmonitorparams('uminnofficedesk');



%% monitor parameter (mp)
%mp = getmonitorparams('uminn7tpsboldscreen');
mp.monitorrect = [0 0 mp.resolution(1) mp.resolution(2)];

%% stimulus parameters (sp)
sp.expname = 'gambling';
sp.nTrial = 24;
sp.moneyoffer = [20, 5];
sp.prob = {rand(1,sp.nTrial), rand(1,sp.nTrial)};  % randomize probility for two offers
sp.posjitter = {rand(1,sp.nTrial), rand(1,sp.nTrial)};  % to gitter position a little bit.
design = getranddesign(sp.nTrial, [2 2]);
sp.loc = design(:,2); % 1,20 dollar offer on the left;2, 20 dollor offer on the right. 
sp.whofirst = design(:,3); % 1,20 dollar offer first;2, 5 dollor offer first. 
sp.colorintensity = 200; 
sp.color = {[sp.colorintensity,0,0], [0,0,sp.colorintensity]};  % bar colors for 20 and 5.
sp.ecc = 6; % deg
sp.barsize = [4.08, 11.35];  % width,height
sp.barlinewidth = 5; % pixels of the bar line Width
sp.stimtime = {[2,2],[2,2],[2,4]}; % secs, timing for three phases; [A,B], A is the stimulus onset time; B is blank
sp.fixsize = 10; % pixel, size of fixation dot
sp.fixcolor = [255 255 255];
sp.grayval = 127;
sp.blackval = 0;
sp.whiteval = 254;

%% calculate more stimulus parameters
sp.eccpix = round(sp.ecc * mp.pixperdeg(1));
sp.barsizepix = round(sp.barsize * mp.pixperdeg(1));
sp.barrect = [0 0 sp.barsizepix(1) sp.barsizepix(2)]; % bar rect 
sp.barrectleft = CenterRect(sp.barrect, mp.monitorrect) + [-sp.eccpix 0 -sp.eccpix 0];   % bar rect on left of the screen
sp.barrectright = CenterRect(sp.barrect,mp.monitorrect) + [sp.eccpix 0 sp.eccpix 0];   % bar rect on left of the screen
sp.fixRect = CenterRect([0 0 sp.fixsize, sp.fixsize], mp.monitorrect);

%% make the stimulus images
% make $20 bar, red
bar20 = zeros([sp.barsizepix(2) sp.barsizepix(1) 3 sp.nTrial]);
bar20(1:sp.barlinewidth, :, find(sp.color{1}>0), :) = sp.colorintensity;  % add border lines
bar20(:, 1:sp.barlinewidth, find(sp.color{1}>0), :) = sp.colorintensity;
bar20(end - sp.barlinewidth:end, :, find(sp.color{1}>0), :) = sp.colorintensity;
bar20(:, end - sp.barlinewidth:end, find(sp.color{1}>0), :) = sp.colorintensity;
% fill color of the bar
for i=1:size(bar20, 4)
    jitter = floor(sp.posjitter{1}(i) * sp.barsizepix(2)*(1- sp.prob{1}(i))) + 1;  % add position jitter within the bar
    bar20(jitter:round(sp.barsizepix(2)*sp.prob{1}(i)) + jitter, :, find(sp.color{1}>0), i) = sp.colorintensity;
end

% make $5 bar, red
bar05 = zeros([sp.barsizepix(2) sp.barsizepix(1) 3 sp.nTrial]);
bar05(1:sp.barlinewidth, :, find(sp.color{2}>0), :) = sp.colorintensity;
bar05(:, 1:sp.barlinewidth, find(sp.color{2}>0), :) = sp.colorintensity;
bar05(end - sp.barlinewidth:end, :, find(sp.color{2}>0), :) = sp.colorintensity;
bar05(:, end - sp.barlinewidth:end, find(sp.color{2}>0), :) = sp.colorintensity;
% fill color of the bar
% fill color of the bar
for i=1:size(bar05, 4)
    jitter = floor(sp.posjitter{2}(i) * sp.barsizepix(2)*(1- sp.prob{2}(i))) + 1;  % add position jitter within the bar
    bar05(jitter:round(sp.barsizepix(2)*sp.prob{2}(i)) + jitter, :, find(sp.color{2}>0), i) = sp.colorintensity;
end

sp.bar20 = bar20;
sp.bar05 = bar05;

%% make arguments for ptviewmovie function, saved as into stimulus parameters
% note that modified ptviewmoview.
% now that here we define 'frame', which is not the 'frame' in monitor
% sense. It is smallest unit we gonna manipulate screen flip.
sp.blank = 16;  % secs, blanck at the begining and the end
%sp.frameduration = 120;  % 120 monitor refresh, that is one second / frame.
sp.stimunitsecs = sp.frameduration / mp.refreshRate;  % secs in a frame here
sp.totaltime = 14 * sp.nTrial + 16 * 2;  % secs, 12 seconds * nTrial + 16 blanks x 2 at beginging and end
sp.offset = {[-sp.eccpix, 0], [sp.eccpix, 0]};  % left, right
sp.frameorder = [zeros(1, sp.blank) repmat([1 1 0 0 2 2 0 0 3 3 0 0 0 0], 1, sp.nTrial) zeros(1, sp.blank)];
sp.trialidx = [zeros(1,sp.blank) sort(mod2(1:sp.nTrial * 14, sp.nTrial)) zeros(1,sp.blank)];
%% MRI related preparation
% some auxillary variables
sp.timekeys = {};
sp.triggerkey = '5';
sp.timeframes=zeros(1, length(sp.frameorder));
getoutearly = 0;
when = 0;
glitchcnt = 0;

% get information about the PT setupr
oldclut = pton([],[],[],1);
win = firstel(Screen('Windows'));
rect = Screen('Rect',win);
Screen('BlendFunction',win,GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
mfi = Screen('GetFlipInterval',win);  % re-use what was found upon initialization!

% wait for a key press to start
Screen('FillRect',win,sp.blackval,rect);
Screen('FrameOval', win, sp.fixcolor,CenterRect([0 0 sp.fixsize sp.fixsize], rect));
Screen('TextSize',win,30);Screen('TextFont',win,'Arial');
Screen('DrawText', win, 'Waiting for experiment to start ...',rect(3)/2-300, rect(4)/2-50, 127);
Screen('Flip',win);
fprintf('press a key to begin the movie. (make sure to turn off network, energy saver, spotlight, software updates! mirror mode on!)\n');
safemode = 0;
while 1
  [secs,keyCode,deltaSecs] = KbWait(-3,2);
  temp = KbName(keyCode);
  if isequal(temp(1),'=')
    if safemode
      safemode = 0;
      fprintf('SAFE MODE OFF (the scan can start now).\n');
    else
      safemode = 1;
      fprintf('SAFE MODE ON (the scan will not start).\n');
    end
  else
    if safemode
    else
      if isempty(sp.triggerkey) || isequal(temp(1),sp.triggerkey)
        break;
      end
    end
  end
end
fprintf('Experiment starts!')
Screen('Flip',win);
% issue the trigger and record it
 
%% now run the experiment
% get trigger

for framecnt = 1:length(sp.frameorder)

    if getoutearly
        break;
    end
    
    % figure the drawing type
    if sp.frameorder(framecnt) == 0  % blank image
        % in this case only draw a fixation point
        Screen('FrameOval', win, sp.fixcolor,CenterRect([0 0 sp.fixsize sp.fixsize], rect));
    else
        % figure out the rect location and who comes first
        barrect1 = choose(sp.loc(sp.trialidx(framecnt))==1, sp.barrectleft, sp.barrectright);
        barrect2 = choose(sp.loc(sp.trialidx(framecnt))==1, sp.barrectright, sp.barrectleft);
        if sp.whofirst(sp.trialidx(framecnt)) == 1  % 20 dollor offer first
            barTex1 = Screen('MakeTexture',win,sp.bar20(:,:,:,sp.trialidx(framecnt)));
            barTex2 = Screen('MakeTexture',win,sp.bar05(:,:,:,sp.trialidx(framecnt)));
        elseif sp.whofirst(sp.trialidx(framecnt)) == 2 % 5 dollor offer first
            barTex1 = Screen('MakeTexture',win,sp.bar20(:,:,:,sp.trialidx(framecnt)));
            barTex2 = Screen('MakeTexture',win,sp.bar05(:,:,:,sp.trialidx(framecnt)));
        end
        
        % draw the texture
        if sp.frameorder(framecnt) == 1  % show first offer
            Screen('FrameOval', win, sp.fixcolor,CenterRect([0 0 sp.fixsize sp.fixsize], rect));
            Screen('DrawTexture', win, barTex1, [], barrect1);
        elseif sp.frameorder(framecnt) == 2  % show second offer
            Screen('FrameOval', win, sp.fixcolor,CenterRect([0 0 sp.fixsize sp.fixsize], rect));
            Screen('DrawTexture', win, barTex2, [], barrect2);
        elseif sp.frameorder(framecnt) == 3  % show both offer
            Screen('FrameOval', win, sp.fixcolor,CenterRect([0 0 sp.fixsize sp.fixsize], rect));
            Screen('DrawTexture', win, barTex1, [], barrect1);
            Screen('DrawTexture', win, barTex2, [], barrect2);
        end        
    end
    
    % detect button press
    while 1
        % if we are in the initial case OR if we have hit the when time, then display the frame
        if when == 0 || GetSecs >= when
            % issue the flip command and record the empirical time
            [VBLTimestamp,StimulusOnsetTime,FlipTimestamp,Missed,Beampos] = Screen('Flip',win, when);
            %      sound(sin(1:2000),100);
            sp.timeframes(framecnt) = VBLTimestamp;
            
            % if we missed, report it
            if Missed > 0 & when ~= 0
                glitchcnt = glitchcnt + 1;
                didglitch = 1;
            else
                didglitch = 0;
            end
            % get out of this loop
            break;
            
            % otherwise, try to read input
        else
            [keyIsDown,secs,keyCode,deltaSecs] = KbCheck(-3);  % all devices
            if keyIsDown
                % get the name of the key and record it
                kn = KbName(keyCode);
                kn
                sp.timekeys = [sp.timekeys; {secs kn}];
                
                % check if ESCAPE was pressed
                if isequal(kn,'ESCAPE')
                    fprintf('Escape key detected.  Exiting prematurely.\n');
                    getoutearly = 1;
                    break;
                end
                
            end
          
        end
        
    end
    
    % write to file if desired
    if sp.wantframefiles
       imwrite(Screen('GetImage',win),sprintf('Frame%03d.png',framecnt));
    end
    
    % update when
    if didglitch
        % if there were glitches, proceed from our earlier when time.
        % set the when time to half a frame before the desired frame.
        % notice that the accuracy of the mfi is strongly assumed here.
        when = (when + mfi / 2) + mfi * sp.frameduration - mfi / 2;
    else
        % if there were no glitches, just proceed from the last recorded time
        % and set the when time to half a frame before the desired time.
        % notice that the accuracy of the mfi is only weakly assumed here,
        % since we keep resetting to the empirical VBLTimestamp.
        when = VBLTimestamp + mfi * sp.frameduration - mfi / 2;  % should we be less aggressive??
    end
    
end
ptof(oldclut);
%% clean up and save data
rmpath(genpath('./utils'));  % remove the utils path
c = fix(clock);
filename=sprintf('%d%02d%02d%02d%02d%02d_exp%s_sub%s_run%02d',c(1),c(2),c(3),c(4),c(5),c(6),sp.expname,sp.subj,sp.runnum);
save(filename); % save everything to the file;
