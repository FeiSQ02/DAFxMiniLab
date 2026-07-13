clc;close all;clear;
%% add wavfile 
filename = '../../data/in.wav';
% info = audioinfo(filename);
[x0, fs] = audioread(filename);
x = wavCut(filename, [135 140]);
% sound(x, fs);
% plot(x);


%% CrossFade
sig1 = x(end:-1:1);
sig2 = x;
fadeSec = 5;
% square-root fade
sig1Len = length(sig1);
sig2len = length(sig2);
aIn = linspace(0, 1, fadeSec*fs);
fadeIn = aIn.^(1/2);
aOut = aIn(end:-1:1);

totalLen = max(sig1Len, sig2len);
y = zeros(totalLen, 1);
for i = 1:totalLen
    y(i) = aOut(i)*sig1(i) + aIn(i)*sig2(i);
end
sound(y, fs);