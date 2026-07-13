clc;close all;clear;
%% add wavfile 
filename = '../data/in.wav';
% info = audioinfo(filename);
[x0, fs] = audioread(filename);
x = wavCut(filename, [135 140]);
% sound(x, fs);
% plot(x);


%% RING MODULATION
x_len = length(x);
y1 = zeros(x_len, 1);
% 核心玩法：尝试修改这里的 fc！
% fc < 20 Hz  : 颤音效果 (Tremolo)，听起来声音在抖动
% fc = 50~100 Hz : 咆哮感、粗糙感 (低频 Ring Mod)
% fc > 300 Hz : 明显的金属声、钟声、外星人音效
% -----------------------------------------------------
fc_base = 500; % 载波频率设置 (单位：Hz)
mix = 0.3; 
lfo_f = 0.05;
drive = 1.5; % 模拟饱和度

% Synthesize modulation signal
t = (0:x_len-1)/fs;
fc = fc_base + 100*sin(2*pi*lfo_f*t');
mod = sawtooth(2*pi*fc.*t', 0.5);

for i = 1:x_len
    y1(i) = x(i)*mod(i);
    y1(i) = tanh(y1(i)*drive);
    y1(i) = mix*y1(i) + (1-mix)*x(i);
end
sound(y1, fs);
