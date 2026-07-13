function [y] = wavCut(filePath,secRange)
%WAVCUT 此处显示有关此函数的摘要
%   此处显示详细说明
[x, fs] = audioread(filePath);
idx1 = round(secRange(1)*fs)+1;
idx2 = round(secRange(2)*fs);
y = x(idx1:idx2, :);
% audiowrite(savePath, y, fs);
end

