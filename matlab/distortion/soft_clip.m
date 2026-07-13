clc; close all; clear;

%% ============================================================
%  soft_clip.m — TS808 Tube Screamer Style Overdrive
% ============================================================
%  Models the classic overdrive pedal signal chain:
%    1. Pre-emphasis HPF  →  reduce low-end mud before clipping
%    2. Drive / gain       →  push signal into the clipping stage
%    3. Soft clip (tanh)  →  symmetrical diode-style saturation
%    4. Tone control (LPF) →  shape high-frequency content
%    5. Output level       →  final volume
%
%  All parameters are configurable below.
% ============================================================

%% --- Load test audio ---
filename = '../data/in.wav';
[x, fs] = audioread(filename);

%% Optional: cut a short segment for faster testing
% x = wavCut(filename, [135 140]);

%% 调节输入电平
x = InputGainSet(x);
% x = InputGainSet(x, 0, fs);

% mono effect
x = x(:, 1);                     % use left channel only for clarity

N = length(x);
t = (0:N-1)' / fs;

%% --- User parameters (tweak these!) ---
drive  = 6;       % pre-gain multiplier   (1 ~ 20, TS808 sweet spot 3~10)
tone   = 0.5;     % tone knob             (0 = dark, 1 = bright)
level  = 0.8;     % output volume         (0 ~ 1)

% Pre-emphasis HPF cutoff (Hz) — reduces mud before clipping
hpCutoff = 720;   % typical TS value ~720 Hz

% Tone filter cutoff range (Hz)
toneMin  = 300;   % darkest
toneMax  = 4000;  % brightest

%% --- 1. Pre-emphasis HPF (1st-order) ---
%  H(s) = s / (s + wc)
wc   = 2 * pi * hpCutoff;
alpha = 1 / (1 + wc * (1/fs));         % bilinear-derived coefficient
xPre = filter([1, -1], [1, -alpha], x);  % leaky differentiator = HPF

%% --- 2. Drive ---
xDriven = drive * xPre;

%% --- 3. Soft clip (tanh) ---
%  tanh provides a smooth, symmetrical saturation that mimics
%  silicon-diode feedback clipping in a TS-style op-amp stage.
yClip = tanh(xDriven);

%% --- 4. Tone control (1st-order LPF) ---
%  Tone knob sweeps cutoff between toneMin and toneMax (log scale)
cutoff = toneMin * (toneMax / toneMin)^tone;   % log-taper feel
[lpB, lpA] = butter(1, cutoff/(fs/2), 'low');
yTone = filter(lpB, lpA, yClip);

%% --- 5. Output level ---
y = level * yTone / max(abs(yTone));   % normalize then scale

%% --- Play result ---
fprintf('Playing processed audio (drive=%.1f, tone=%.2f, level=%.2f)...\n', drive, tone, level);
sound(y, fs);

%% ============================================================
%  Visualization
% ============================================================

figure('Name', 'TS808 Soft Clip Analysis', 'Position', [100 100 1000 700]);

% --- (a) Transfer curve ---
subplot(2,3,1);
xx = linspace(-1, 1, 1000);
yy = level * tanh(drive * xx);
yy = yy / max(abs(yy)) * level;
plot(xx, yy, 'LineWidth', 1.5); grid on;
xlabel('Input'); ylabel('Output');
title(sprintf('Transfer Curve (drive = %.1f)', drive));
xlim([-1 1]); ylim([-1 1]);
axis equal;

% --- (b) Waveform: original vs processed (zoom) ---
subplot(2,3,[2 3]);
plotRange = 1:min(2000, N);
plot(t(plotRange)*1000, x(plotRange), 'Color', [0.6 0.6 0.6], 'LineWidth', 1); hold on;
plot(t(plotRange)*1000, y(plotRange), 'b', 'LineWidth', 1); hold off;
xlabel('Time (ms)'); ylabel('Amplitude');
legend('Original', 'TS808');
title('Waveform Comparison');
grid on;

% --- (c) Spectrum before vs after ---
subplot(2,3,[4 5]);
nfft = min(8192, N);
[Px, fx] = pwelch(x, hann(nfft), nfft/2, nfft, fs);
[Py, fy] = pwelch(y, hann(nfft), nfft/2, nfft, fs);
semilogx(fx, 10*log10(Px), 'Color', [0.6 0.6 0.6], 'LineWidth', 1); hold on;
semilogx(fy, 10*log10(Py), 'b', 'LineWidth', 1); hold off;
xlabel('Frequency (Hz)'); ylabel('Power/Frequency (dB/Hz)');
legend('Original', 'TS808');
title('Spectrum Comparison');
grid on; xlim([20 fs/2]);

% --- (d) Harmonic structure (single-tone test) ---
subplot(2,3,6);
% Generate a 220 Hz sine to see harmonic generation clearly
fTest = 220;
tTest = (0:fs-1)' / fs;          % 1 second
xTest = 0.5 * sin(2*pi*fTest*tTest);
xTestHP = filter([1, -1], [1, -alpha], xTest);
yTest = level * tanh(drive * xTestHP);
yTest = filter(lpB, lpA, yTest);
yTest = yTest / max(abs(yTest)) * level;

nfftH = fs;
[Ph, fh] = pwelch(yTest, hann(nfftH), nfftH/2, nfftH, fs);
semilogx(fh, 10*log10(Ph), 'r', 'LineWidth', 1); grid on;
xlabel('Frequency (Hz)'); ylabel('Power/Frequency (dB/Hz)');
title(sprintf('Harmonics @ %d Hz Sine', fTest));
xlim([20 5000]);

sgtitle(sprintf('TS808 Soft Clip  |  drive=%.1f  tone=%.2f  level=%.2f', drive, tone, level));

fprintf('Done. Try changing drive (3~10), tone (0~1), and level (0~1).\n');
