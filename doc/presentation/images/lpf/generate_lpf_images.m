addpath('../../../../sketches/arbilpf/');
%O = 80;
%M = 4;
% original = im2double(imread('original.jpg'));
%B = get_pm_lpf(M, O);
% aliased = pixelize(down_up_y(down_up_x(original, M), M), M);
% filtered = pixelize(arbilpf(original, M, M, O), M);
% figure(1); subplot(1,3,1); imshow(original); subplot(1,3,2); imshow(aliased); subplot(1,3,3); imshow(filtered);
% imwrite(original, 'original.png', 'png');
% imwrite(aliased, 'original_aliased.png', 'png');
% imwrite(filtered, 'original_filtered.png', 'png');
%B2 = conv2(B, B')
%[H, Fx, Fy] = freqz2(B2, 1024);
%figure; imshow(log(abs(H)), [-1, 0]); colormap(jet);
%saveas(gcf, 'filter_mag.png', 'png');

% 1
original = imread('lpf-operation/original.jpg');
original = im2double(original);
figure; imshow(log(abs(fftshift(fft2(rgb2gray(original))))), [-1, 5]); colormap(jet);
saveas(gcf, 'lpf-operation/orig_mag.png', 'png');
% 2
My = 8;
By = get_pm_lpf(My, 120);
[H, W] = freqz(By, [1], 1024);
figure; plot(W, abs(H)); xlabel('Normalized Frequency (x\pi rad/s)');
saveas(gcf, 'lpf-operation/y-filter.png', 'png');
% 3
processed = filter_cols(original, By);
figure; imshow(log(abs(fftshift(fft2(rgb2gray(processed))))), [-1, 5]); colormap(jet);
saveas(gcf, 'lpf-operation/proc_mag.png', 'png');
%3
Mx = 16;
Bx = get_pm_lpf(Mx, 180);
[H, W] = freqz(Bx, [1], 1024);
figure; plot(W, abs(H)); xlabel('Normalized Frequency (x\pi rad/s)');
saveas(gcf, 'lpf-operation/x-filter.png', 'png');
% 4
processed = filter_rows(processed, Bx);
figure; imshow(log(abs(fftshift(fft2(rgb2gray(processed))))), [-1, 5]); colormap(jet);
saveas(gcf, 'lpf-operation/output_mag.png', 'png');
% 5
B2 = conv2(Bx, By');
[H, Fx, Fy] = freqz2(B2, 1024);
figure; imshow(log(abs(H)), [-4, 0]); colormap(jet);
saveas(gcf, 'lpf-operation/total_filt.png', 'png');
% 6
imwrite(processed, 'lpf-operation/output.png', 'png');
close all;
