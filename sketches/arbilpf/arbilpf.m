function [Y] = arbilpf(X, M, N, dW)
% Y = abrilpf(X,M)
% X  - WxL or WxLx3 matrix containing the image data (should be of double precision)
% N  - length of 1D LPF filter that is transformed to two dimensions (good ranges: 30-50)
% dW - width of transition region of the LPF, in radians (increase for less ripple; dW = 0.05 is good)
% M  - downsampling coefficient
% Y  - lowpassed version of X with pi/M as the radial cutoff frequency

Y = zeros(size(X));

% MATLAB command that I experimented with:
% f = [0, 0.45, 0.55, 1]; a = [1, 1, 0, 0]; N = 50;
% h1d = firpm(N, f, a); [H1d, w] = freqz(h1d, 1, 1e4);
% plot(f, a, w/pi, abs(H1d));
% h2d = ftrans2(h1d)
% freqz2(h2d) - plots the 2d frequency response of h2d

h1d = firpm(N, [0, (1/M-dW), (1/M+dW), 1], [1, 1, 0, 0]);
h2d = ftrans2(h1d);
% freqz2(h2d)
for i=1:size(Y, 3)
	Y(:,:,i) = conv2(X(:,:,i), h2d, 'same');
end

end
