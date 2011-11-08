% simply testing arbilpf

img_orig = imread('IMG_5046.jpg', 'jpg');
img_orig_d = im2double(img_orig);
Mx = 10; % downsampling factor
My = 2;
N = 60; % 40 seems like a reasonable filter order
img_lpf = arbilpf(img_orig_d, Mx, My, N);
img_lpf_d = im2double(img_lpf);
figure;
subplot(1,2,1); imshow(img_orig); title('Original Image');
subplot(1,2,2); imshow(img_lpf); title('Low Passed Image');
% plot fft of original image
fft_orig = fftshift(fft2(rgb2gray(img_orig_d)));
fft_lpf = fftshift(fft2(rgb2gray(img_lpf_d))); 
figure;
subplot(1,2,1); imshow(log(abs(fft_orig(:,:,1))), [-1, 5]); colormap(jet); colorbar; title('Log Magnitude of FFT of Grayscaled Original');
subplot(1,2,2); imshow(log(abs(fft_lpf(:,:,1))), [-1, 5]); colormap(jet); colorbar; title('Log Magnitude of FFT of Grayscaled LPFd Image');
