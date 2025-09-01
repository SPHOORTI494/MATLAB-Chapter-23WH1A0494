clc; clear; close all;
rng(1);                                   % repeatable results

%% 1) Load grayscale image (original reference)
img = imread('cameraman.tif');            % built-in
img = imresize(img,[256 256]);            % standard size
ref = img;                                % keep ORIGINAL for all comparisons
figure, imshow(ref), title('Original');

%% 2) Bits from image (8 bits per pixel, MSB-first)
pix = double(ref(:));                     % 0..255 as double
bits = de2bi(pix, 8, 'left-msb');         % Npix x 8
tx_bits = bits(:);                        % column bitstream (0/1)
l
%% 3) BPSK mapping (0->-1, 1->+1) and enforce double column
tx_syms = 2*double(tx_bits) - 1;          % ±1
tx_syms = tx_syms(:);                     % column vector

%% 4) Sweep SNR and evaluate
SNRdB = 0:5:20;
psnr_vals = zeros(size(SNRdB));
ssim_vals = zeros(size(SNRdB));

for k = 1:numel(SNRdB)
    snrdb = SNRdB(k);

    % AWGN on symbols (SNR measured vs signal power)
    rx_syms = awgn(tx_syms, snrdb, 'measured');

    % BPSK hard decision
    rx_bits = rx_syms > 0;                % logical column

    % Rebuild pixels from bits (MSB-first to match de2bi)
    rx_bits_mat = reshape(rx_bits, [], 8);            % Npix x 8
    rx_pix = bi2de(rx_bits_mat, 'left-msb');          % 0..255 (double)
    rx_img = uint8(reshape(rx_pix, size(ref)));        % image

    % Quality vs ORIGINAL
    psnr_vals(k) = psnr(rx_img, ref);
    ssim_vals(k) = ssim(rx_img, ref);

    % Show worst/best cases
    if snrdb==min(SNRdB) || snrdb==max(SNRdB)
        figure, imshow(rx_img), title(sprintf('Received (SNR = %d dB)', snrdb));
    end
end

%% 5) Plot
figure; plot(SNRdB, psnr_vals, '-o','LineWidth',2);
xlabel('SNR (dB)'); ylabel('PSNR (dB)'); title('SNR vs PSNR'); grid on;

figure; plot(SNRdB, ssim_vals, '-s','LineWidth',2);
xlabel('SNR (dB)'); ylabel('SSIM'); title('SNR vs SSIM'); grid on;
