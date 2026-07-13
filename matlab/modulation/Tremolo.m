clc;close all;clear;
%% add wavfile 
filename = '../data/in.wav';
% info = audioinfo(filename);
[x0, fs] = audioread(filename);
x = wavCut(filename, [135 140]); % Input
% sound(x, fs);
% plot(x);

x_len = length(x);
t = (0:x_len-1)/fs;
y1 = zeros(x_len, 1); % Output


%% Tremolo parameters
depth = 60;
speed = 5;
amp = 0.5*(depth/100);


%% Synthesize modulation signal
f = speed;
offset = 1-amp;
sw = sin(2*pi*f.*t');

mod = amp.*sw + offset;


%%
y1 = x.*mod;
sound(y1, fs);