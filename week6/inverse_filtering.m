% inverse filter with thresholding

clear all
close all
clc

% specify the threshold T
T = 5e-1;

%% read in the original, sharp and noise-free image
original = im2double(rgb2gray((imread('original_cameraman.jpg'))));
[H, W] = size(original);

%% generate the blurred and noise-corrupted image for experiment
motion_kernel = ones(1, 9) / 9;  % 1-D motion blur
motion_freq = fft2(motion_kernel, 1024, 1024);  % frequency response of motion blur
original_freq = fft2(original, 1024, 1024); % original image to frequency domain
% blur the image with the motion blur filter
blurred_freq = original_freq .* motion_freq;  % spectrum of blurred image
blurred = ifft2(blurred_freq); % spatial blured image 
blurred = blurred(1 : H, 1 : W); % reconstruct the blured image to match the original image
blurred(blurred < 0) = 0; % all vals > 0
blurred(blurred > 1) = 1; % put a constraint to tapper of any high value
noisy = imnoise(blurred, 'gaussian', 0, 1e-4); % apply the noise filter with the threshold


%% Restoration from blurred and noise-corrupted image
% generate restoration filter in the frequency domain
inverse_freq = zeros(size(motion_freq));
inverse_freq(abs(motion_freq) < T) = 0;
inverse_freq(abs(motion_freq) >= T) = 1 ./ motion_freq(abs(motion_freq) >= T);
% spectrum of blurred and noisy-corrupted image (the input to restoration)
noisy_freq = fft2(noisy, 1024, 1024);
% restoration
restored_freq = noisy_freq .* inverse_freq;
restored = ifft2(restored_freq);
restored = restored(1 : H, 1 : W);
restored(restored < 0) = 0;
restored(restored > 1) = 1;

%% analysis of result
noisy_psnr = 10 * log10(1 / (norm(original - noisy, 2) ^ 2 / H / W));
restored_psnr = 10 * log10(1 / (norm(original - restored, 2) ^ 2 / H / W));

%% ISNR Calculation
ISNR =  10 * log10((mean2((original-noisy).^2)) / (mean2((original-restored).^2)))


%% visualization
figure; imshow(original, 'border', 'tight');
figure; imshow(blurred, 'border', 'tight');
figure; imshow(noisy, 'border', 'tight');
figure; imshow(restored, 'border', 'tight');
figure; plot(abs(fftshift(motion_freq(1, :)))); title('spectrum of motion blur'); xlim([0 1024]);
figure; plot(abs(fftshift(inverse_freq(1, :)))); title('spectrum of inverse filter'); xlim([0 1024]);