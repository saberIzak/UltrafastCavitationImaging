% Adapted from supplied examples by Verasonics and modified to record RF data for high-frame rate ultrasound imaging in a so-called Super-frame.

clear all
% Basic info:
P.soundSpeed = 1480; % in m/s for water case
P.startDepth = 5;
P.endDepth = 38; % in waveform number.
P.numFrames = 40;  % number of frames 
P.sampleRate = 62.5; % in MHz.

% Specify system parameters
Resource.Parameters.numTransmit = 128;   
Resource.Parameters.numRcvChannels = 64; 
Resource.Parameters.speedOfSound = P.soundSpeed; 
Resource.Parameters.verbose = 2;
Resource.Parameters.initializeOnly = 0;
Resource.Parameters.simulateMode = 0; 

% Specify Trans structure array.
Trans.name = 'L7-4';
Trans.frequency = 5; % in MHz
Trans.units = 'wavelengths'; 
Trans = computeTrans(Trans); 

% Specify Resource buffers.
Resource.RcvBuffer(1).datatype = 'int16';
Resource.RcvBuffer(1).rowsPerFrame = 2048*(P.numFrames);
Resource.RcvBuffer(1).colsPerFrame = ...
    Resource.Parameters.numTransmit;
Resource.RcvBuffer(1).numFrames = 1;       

% Specify Transmit waveform structure.
TW(1).type = 'parametric';
TW(1).Parameters = [Trans.frequency,0.67,2,1];

% Specify TX structure array.
TX = struct('waveform', 1, ...
                   'Origin', [0.0,0.0,0.0], ...
                   'focus', 0.0, ...
                   'Steer', [0.0,0.0], ...
                   'Apod', ones(1,128), ...
                   'Delay', zeros(1,Trans.numelements));

% Specify TGC Waveform structure.
TGC(1).CntrlPts = [0,590,650,710,770,830,890,950];      
TGC(1).rangeMax = P.endDepth;
TGC(1).Waveform = computeTGCWaveform(TGC);

% Specify Receive structure array
Receive = repmat(struct(...
                'Apod', [zeros(1,64),ones(1,64)], ...
                'startDepth', P.startDepth, ...
                'endDepth', P.endDepth, ...
                'TGC', 1, ...
                'mode', 0, ...
                'bufnum', 1, ...
                'framenum', 1, ...
                'acqNum', 1, ...
                'sampleMode', 'custom',...
                'decimSampleRate', P.sampleRate) ...
                ,1,P.numFrame);

% - Set event specific Receive attributes.
for i = 1:P.numFrames
    Receive(i).acqNum = i;
end

% Specify an external processing event.
Process(1).classname = 'External';
Process(1).method = 'FastUltrasoundRF_process';
Process(1).Parameters = {'srcbuffer','receive',... 
                         'srcbufnum',1,...
                         'srcframenum',-1,...
                         'dstbuffer','none'};

% Specify sequence events.
SeqControl(1).command = 'triggerIn';
SeqControl(1).condition = 'Trigger_1_Rising';
SeqControl(1).argument = 0; % time im usec
SeqControl(2).command = 'jump';
SeqControl(2).argument = 1;

nsc = 3;
n = 1;   % start index for Events
    
Event(n).info = 'Waiting fot the trigger-in signal.';
Event(n).tx = 0;
Event(n).rcv = 0;
Event(n).recon = 0;
Event(n).process = 0;
Event(n).seqControl = 1;
 n = n+1;
 
for i = 1:P.numFrames
    Event(n).info = 'Aquisition RF';
    Event(n).tx = 1;
    Event(n).rcv = i;
    Event(n).recon = 0;
    Event(n).process = 0;
    Event(n).seqControl = 0;
     n = n+1;
end

Event(n-1).seqControl = [2,nsc]; 
SeqControl(nsc).command = 'transferToHost';
nsc = nsc+1;

Event(n).info = 'Call external Processing function.';
Event(n).tx = 0;
Event(n).rcv = 0;
Event(n).recon = 0;
Event(n).process = 1;
Event(n).seqControl = 0;
n = n+1;

Event(n).info = 'jump  back to event 1';
Event(n).tx = 0;
Event(n).rcv = 0;
Event(n).recon = 0;
Event(n).process = 0;
Event(n).seqControl = 2;

% - Create UI controls for channel selection/
nr = Resource.Parameters.numRcvChannels;
UI(1).Control = {'UserB1','Style','VsSlider',...
                 'Label','Plot Channel',...
                 'SliderMinMaxVal',[1,128,64],...
                 'SliderStep', [1/nr,8/nr],...
                 'ValueFormat', '%3.0f'};
UI(1).Callback = {'assignin(''base'',''myPlotChnl'',round(UIValue));'};
EF(1).Function = vsv.seq.function.ExFunctionDef...
('FastUltrasoundRF_process',@FastUltrasoundRF);
% Save all the structures to a .mat file.
save('../../MatFiles/FastUltrasoundRF_recording');
return

function FastUltrasoundRF(RData)
    
    % LOADING DATA
    Receive = evalin('base','Receive');
    Trans = evalin('base','Trans');
    P = evalin('base','P');
    TX = evalin('base','TX');
    
    save('FastUltrasoundRF_folder/RData.mat','RData');
    save('FastUltrasoundRF_folder/Receive.mat','Receive');
    save('FastUltrasoundRF_folder/Trans.mat','Trans');
    save('FastUltrasoundRF_folder/TX.mat','TX');
    save('FastUltrasoundRF_folder/P.mat','P');
     
end