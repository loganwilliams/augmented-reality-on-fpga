% simply testing arbilpf

img_orig = imread('../arbiskew/IMG_5046.jpg', 'jpg');
img_orig = im2double(img_orig);
% size(img_orig)
% imshow(img_orig);
% M = 3
img_lpf = arbilpf(img_orig, 3, 30, 0.05);
figure;
subplot(1,2,1); imshow(img_orig); title('Original Image');
subplot(1,2,2); imshow(img_lpf); title('Low Passed Image');
% plot fft of original image
fft_orig = fftshift(fft2(rgb2gray(img_orig)));
fft_lpf = fftshift(fft2(rgb2gray(img_lpf))); 
figure;
subplot(1,2,1); imshow(log(abs(fft_orig(:,:,1))), [-1, 5]); colormap(jet); colorbar; title('Log Magnitude of FFT of Grayscaled Original');
subplot(1,2,2); imshow(log(abs(fft_lpf(:,:,1))), [-1, 5]); colormap(jet); colorbar; title('Log Magnitude of FFT of Grayscaled LPFd Image');
