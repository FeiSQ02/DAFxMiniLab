function [y] = InputGainSet(x, manualGain_dB, fs)
% inputGainSet  输入电平调节（自动/手动）
%   y = inputGainSet(x)              自动对齐到 -18 dBFS RMS
%   y = inputGainSet(x, gain_dB)     手动施加 gain_dB 分贝的增益
%
%   注意：此函数不进行任何峰值限制，故意允许信号超过 [-1, 1]，
%   以便为后续模块提供足够的驱动电平。

% 参考目标 RMS（线性值）
targetRMS_dB = -18;                 % 行业标准参考电平
targetRMS    = 10^(targetRMS_dB / 20);

if nargin == 1
    % ----- 自动模式：对齐到参考 RMS -----
    % 计算所有声道的整体 RMS（保持立体声平衡）
    currentRMS = sqrt(mean(x(:).^2));
    if currentRMS < 1e-10
        gain = 1;
    else
        gain = targetRMS / currentRMS;
    end
elseif nargin >= 2
    % ----- 手动模式：直接应用指定增益 -----
    appliedGain_dB = manualGain_dB;
    gain = 10^(appliedGain_dB / 20);
    if nargin == 3
        % 调试模式 可视化原音频电平
        % 每隔固定时间，刷新peak和RMS
        bufferTimeSec = 1; % 缓冲区长度[s]
        bufferLen = round(bufferTimeSec*fs); % timeSec*fs
        N = length(x);
        bufferNums = floor(N / bufferLen);
        timeAxis = ((0:bufferNums-1)' + 0.5) * bufferTimeSec;   % 每块的中心时间
        peak_dB_arr = zeros(bufferNums, 1);
        rms_dB_arr  = zeros(bufferNums, 1);

        for k = 1:bufferNums
            idx_start = (k-1)*bufferLen + 1;
            idx_end   = k*bufferLen;
            chunk = x(idx_start:idx_end);

            % 峰值
            peak = max(abs(chunk));
            peak_dB_arr(k) = 20 * log10(peak + eps);

            % RMS（去直流，更准确）
            chunk_ac = chunk - mean(chunk);
            rms_val = sqrt(mean(chunk_ac.^2));
            rms_dB_arr(k) = 20 * log10(rms_val + eps);
        end

        % 画图
        figure('Name', '输入电平时间历程');
        plot(timeAxis, peak_dB_arr, 'r-o', 'LineWidth', 1, 'MarkerSize', 4); hold on;
        plot(timeAxis, rms_dB_arr,  'b-o', 'LineWidth', 1, 'MarkerSize', 4);
        xlabel('时间 (秒)'); ylabel('电平 (dBFS)');
        legend('峰值 Peak', 'RMS');
        title('原始音频电平随时间变化');
        grid on; ylim([-60 0]);
        hold off;
    end
else
    error('输入参数个数必须为 1 或 2 或 3。');
end

% 施加固定增益（不改变波形内部相对关系）
gain

y = x * gain;

gain_db = 20*log(gain) % 可选。返回增益db

end

