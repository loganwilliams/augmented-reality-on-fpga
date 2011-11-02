function [Y] = arbilpf(X, M, r, w, K)
% Y = abrilpf(X,M)
% X - WxL or WxLx3 matrix containing the image data (should be of integer precision!)
% M - downsampling coefficient
% r - maximum passband ripple (good values: r <= 0.05)
% w - width of transition region as a fraction of the passband of the LPF,
%     ie, width of transition = w*(1/M) (w = 0.1 is good)
% K - ratio of stopband ripple to passband ripple (the lower it is, the larger the filter)
% Y - lowpassed version of X with pi/M as the radial cutoff frequency

Y = zeros(size(X));

% MATLAB command that I experimented with:
% f = [0, 0.45, 0.55, 1]; a = [1, 1, 0, 0]; N = 50;
% h1d = firpm(N, f, a); [H1d, w] = freqz(h1d, 1, 1e4);
% plot(f, a, w/pi, abs(H1d));
% h2d = ftrans2(h1d)
% freqz2(h2d) - plots the 2d frequency response of h2d

dW = w/M;
N = 10; % starting length - 1
err = r+0.1; % magnitude of the ripple
while (err > r) % find lowest order filter that meets ripple specification
	N = N+2; % N must be even for ftrans2
	[h1d, err] = firpm(N, [0, (1/M-dW/2), (1/M+dW/2), 1], [1, 1, 0, 0], [K, 1]);
	err = err/K;
end
h2d = ftrans2(h1d);

% debugging statements
filter_order = sprintf('1D filter length: %d; 2D filter size: %d', N+1, (size(h2d,1)*size(h2d,2))); disp(filter_order);
% H1d = freqz(h1d);
% figure; plot(linspace(-1, 1, size(H1d, 1)), abs(H1d));
% freqz2(h2d)

% for i=1:size(Y, 3)
%	Y(:,:,i) = conv2(X(:,:,i), h2d, 'same');
%end

% using imfilter to speed up computation
Y = imfilter(X, h2d, 'symmetric', 'same', 'conv');

end
