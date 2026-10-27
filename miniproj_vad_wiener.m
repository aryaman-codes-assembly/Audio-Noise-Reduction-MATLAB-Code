%% ========================================================================
%  LIVE MICROPHONE + WIENER FILTER + SPECTRAL ENHANCEMENT
%  With realistic keyboard clicks + fixed complex-number bug.
%  ========================================================================

clear; clc; close all;

%% --- STEP 1: LIVE RECORDING (with countdown) ---
fs = 16000;
duration = 6;
recObj = audiorecorder(fs, 16, 1);

disp('========================================');
disp('  GET READY TO SPEAK...');
disp('========================================');

for i = 3:-1:1
    fprintf('  Recording starts in %d...\n', i);
    pause(1);
end

disp('🔴 RECORDING NOW - Speak naturally for 6 seconds!');
recordblocking(recObj, duration);
disp('✅ Recording finished.');

clean = getaudiodata(recObj);
clean = clean / (max(abs(clean)) + 1e-12);
clean = real(clean);            % Ensure real from the start
t = (0:length(clean)-1)/fs;

%% --- STEP 2: ADD SYNTHETIC NOISE (realistic clicks) ---
noisy = add_noise(clean, fs, 10, 0.05);

%% --- STEP 3: STAGE 1 - LINEAR FILTERING ---
filtered_lpf = linear_filter(noisy, fs, 50, 30, 3400, 10);

%% --- STEP 4: STAGE 2 - WIENER FILTER ---
[denoised, vad_info] = wiener_filter_v2(filtered_lpf, fs, 0.02);

%% --- STEP 5: STAGE 3 - FREQUENCY-DOMAIN VOICE ENHANCEMENT ---
enhanced = enhance_clarity(denoised, fs);

% Safety: ensure real and float
enhanced = real(enhanced);
enhanced = double(enhanced);

fprintf('Input RMS:  %.4f\n', rms(denoised));
fprintf('Output RMS: %.4f\n', rms(enhanced));
fprintf('Clarity boost: %.2f x\n', rms(enhanced)/rms(denoised));

%% --- STEP 6: PLAYBACK (with countdown) ---
disp('========================================');
disp('🔊 Playing ORIGINAL (Noisy) recording...');
disp('========================================');
sound(real(noisy), fs);
pause(duration + 0.5);

disp('========================================');
disp('🔊 Playing DENOISED (before enhancement)...');
disp('========================================');
sound(real(denoised), fs);
pause(duration + 0.5);

disp('========================================');
disp('🔊 Playing ENHANCED (final output)...');
disp('========================================');
sound(enhanced, fs);
pause(duration + 0.5);

disp('✅ Playback complete.');

%% ========================================================================
%  FIGURE 1: 5-PANEL PIPELINE ANALYSIS
%% ========================================================================
figure('Name', 'Figure 1: Full Pipeline', 'Position', [50 50 1400 1000]);
theme('dark');

subplot(5, 1, 1);
plot(t, clean, 'g', 'LineWidth', 1.5);
title('1. Clean Speech (Recorded from Mic)', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('Amp'); grid on; xlim([0 duration]); ylim([-1 1]);

subplot(5, 1, 2);
plot(t, noisy, 'r', 'LineWidth', 1);
title('2. Noisy Speech (10 dB SNR + Realistic Keyboard Clicks)', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('Amp'); grid on; xlim([0 duration]); ylim([-1 1]);

subplot(5, 1, 3);
plot(t, filtered_lpf, 'm', 'LineWidth', 1.2);
title('3. After Notch + LPF (Stage 1)', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('Amp'); grid on; xlim([0 duration]); ylim([-1 1]);

subplot(5, 1, 4);
plot(t, denoised, 'c', 'LineWidth', 1.2);
title('4. After Wiener Filter (Denoised)', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('Amp'); grid on; xlim([0 duration]); ylim([-1 1]);

subplot(5, 1, 5);
plot(t, enhanced, 'b', 'LineWidth', 1.5);
title('5. After Spectral Enhancement (Final Output)', 'FontSize', 11, 'FontWeight', 'bold');
xlabel('Time (s)'); ylabel('Amp'); grid on; xlim([0 duration]); ylim([-1 1]);

%% ========================================================================
%  FIGURE 2: SPECTRUM COMPARISON
%% ========================================================================
figure('Name', 'Figure 2: Spectrum Before/After Enhancement', 'Position', [100 100 1400 700]);
theme('dark');

N = length(denoised);
f_axis = fs*(0:(N/2))/N;

Y_before = abs(fft(real(denoised)))/N; Y_before = Y_before(1:N/2+1);
Y_before(2:end-1) = 2*Y_before(2:end-1);

Y_after = abs(fft(real(enhanced)))/N; Y_after = Y_after(1:N/2+1);
Y_after(2:end-1) = 2*Y_after(2:end-1);

subplot(3, 1, 1);
plot(f_axis, 20*log10(Y_before+1e-12), 'c', 'LineWidth', 1.2);
title('Spectrum BEFORE Enhancement', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Magnitude (dB)'); grid on; xlim([0 4000]);

subplot(3, 1, 2);
plot(f_axis, 20*log10(Y_after+1e-12), 'b', 'LineWidth', 1.2);
title('Spectrum AFTER Enhancement', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Magnitude (dB)'); grid on; xlim([0 4000]);

subplot(3, 1, 3);
plot(f_axis, 20*log10(Y_after+1e-12) - 20*log10(Y_before+1e-12), 'y', 'LineWidth', 1.5);
hold on;
yline(0, 'w--', 'LineWidth', 1);
title('Difference (After - Before): Boost per Frequency', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Frequency (Hz)'); ylabel('Gain (dB)'); grid on; xlim([0 4000]);

%% ========================================================================
%  FIGURE 3: NOISE FRAME DETECTION
%% ========================================================================
figure('Name', 'Figure 3: Noise Frame Detection', 'Position', [150 150 1400 900]);
theme('dark');

frame_len = vad_info.frame_len;
hop = vad_info.hop;
num_frames = vad_info.num_frames;
frame_times = ((0:num_frames-1) * hop + frame_len/2) / fs;

subplot(3, 1, 1);
plot(t, filtered_lpf, 'c', 'LineWidth', 0.8); hold on;
noise_idx = vad_info.is_noise_frame;
ylims = [-1 1];
for i = 1:num_frames
    if noise_idx(i)
        start_t = ((i-1)*hop) / fs;
        end_t   = ((i-1)*hop + frame_len) / fs;
        patch([start_t end_t end_t start_t], [ylims(1) ylims(1) ylims(2) ylims(2)], ...
              'r', 'FaceAlpha', 0.25, 'EdgeColor', 'none');
    end
end
title(sprintf('Noise Frame Detection: %d/%d frames flagged as NOISE', ...
      sum(noise_idx), num_frames), 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Amp'); grid on; xlim([0 duration]); ylim(ylims);

subplot(3, 1, 2);
stem(frame_times, vad_info.energy, 'o', 'MarkerSize', 3, 'Color', [1 0.5 0]);
hold on;
yline(vad_info.energy_thresh, 'r--', 'LineWidth', 2, ...
      'Label', sprintf('Quietest 15%% = %.4f', vad_info.energy_thresh));
title('Short-Term Energy per Frame', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Energy'); grid on; xlim([0 duration]);

subplot(3, 1, 3);
stem(frame_times, vad_info.zcr, 'o', 'MarkerSize', 3, 'Color', [0.7 0.3 1]);
title('Zero-Crossing Rate per Frame', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Time (s)'); ylabel('ZCR'); grid on; xlim([0 duration]);

disp('✅ All figures generated.');


%% ========================================================================
%  LOCAL FUNCTIONS
%% ========================================================================

% --- add_noise.m (REALISTIC CLICKS) ---
function noisy = add_noise(clean, fs, snr_db, click_ratio)
    % Additive noise: WGN + realistic keyboard clicks.
    % Realistic clicks: short, broadband, varied, quieter.
    
    % ---- 1. White Gaussian Noise at target SNR ----
    sig_power = mean(clean.^2);
    noise_power = sig_power / (10^(snr_db/10));
    wgn = sqrt(noise_power) * randn(size(clean));
    
    % ---- 2. Realistic keyboard clicks ----
    kb_noise = zeros(size(clean));
    n_clicks = max(1, round(length(clean) * click_ratio));
    
    for i = 1:n_clicks
        % Random position
        start = randi(length(clean) - round(fs/100));
        
        % REALISTIC: short duration (2-5 ms)
        click_len = round(fs * (0.002 + 0.003*rand));   % 2-5 ms
        t_click = (0:click_len-1)'/fs;
        
        % REALISTIC: broadband, not tonal — random noise burst
        click_wav = randn(click_len, 1);
        
        % REALISTIC: very fast exponential decay (10-20 ms time constant)
        decay_rate = 200 + 300*rand;                     % 200-500 per second
        envelope = exp(-t_click * decay_rate);
        click_wav = click_wav .* envelope;
        
        % REALISTIC: bandpass to keyboard-click range (1-4 kHz)
        [b_bp, a_bp] = butter(2, [1000 4000]/(fs/2), 'bandpass');
        click_wav = filter(b_bp, a_bp, click_wav);
        
        % REALISTIC: vary the amplitude per click (some clicks are louder)
        amp_scale = 0.15 + 0.35*rand;                    % 0.15-0.50
        click_wav = click_wav * amp_scale;
        
        % Insert into buffer (handle boundary)
        end_idx = min(start + click_len - 1, length(kb_noise));
        actual_len = end_idx - start + 1;
        kb_noise(start:end_idx) = kb_noise(start:end_idx) + click_wav(1:actual_len);
    end
    
    % ---- 3. Combine ----
    noisy = clean + wgn + kb_noise;
    noisy = real(noisy);
    noisy = noisy / (max(abs(noisy)) + 1e-12);
end

% --- linear_filter.m ---
function y = linear_filter(x, fs, notch_freq, notch_q, lpf_cutoff, lpf_order)
    wo = notch_freq / (fs/2);
    bw = wo / notch_q;
    [b_notch, a_notch] = iirnotch(wo, bw);
    [b_lpf, a_lpf] = butter(lpf_order, lpf_cutoff/(fs/2), 'low');
    y_notch = filtfilt(b_notch, a_notch, real(x));
    y = filtfilt(b_lpf, a_lpf, y_notch);
    y = real(y) / (max(abs(y)) + 1e-12);
end

% --- wiener_filter_v2.m ---
function [y, info] = wiener_filter_v2(x, fs, beta)
    frame_len = round(0.025 * fs);
    hop = round(0.010 * fs);
    win = hamming(frame_len, 'periodic');
    [S, ~, ~] = stft(real(x), fs, 'Window', win, ...
                     'OverlapLength', frame_len-hop, 'FFTLength', frame_len);
    mag = abs(S); phase = angle(S);
    num_frames = size(mag, 2);
    frame_power = sum(mag.^2, 1);
    [sorted_power, sort_idx] = sort(frame_power);
    num_noise_frames = max(10, round(0.15 * num_frames));
    is_noise_frame = false(num_frames, 1);
    is_noise_frame(sort_idx(1:num_noise_frames)) = true;
    energy_thresh = sorted_power(num_noise_frames);
    fprintf('Noise-frame selection: %d / %d frames (quietest 15%%)\n', ...
            num_noise_frames, num_frames);
    noise_power = mean(mag(:, is_noise_frame).^2, 2) + 1e-12;
    obs_power   = mag.^2;
    alpha_dd = 0.98;
    snr_smooth = zeros(size(mag));
    prev_gain_sq = zeros(size(mag,1), 1);
    for t_idx = 1:num_frames
        snr_rough = max(obs_power(:,t_idx) ./ noise_power - 1, 0);
        snr_smooth(:,t_idx) = alpha_dd * (prev_gain_sq .* obs_power(:,t_idx) ./ noise_power) ...
                            + (1 - alpha_dd) * snr_rough;
        g = snr_smooth(:,t_idx) ./ (1 + snr_smooth(:,t_idx));
        prev_gain_sq = g.^2;
    end
    wiener_gain = snr_smooth ./ (1 + snr_smooth);
    smooth_alpha = 0.85;
    wiener_gain_smooth = zeros(size(wiener_gain));
    wiener_gain_smooth(:,1) = wiener_gain(:,1);
    for t_idx = 2:num_frames
        wiener_gain_smooth(:,t_idx) = smooth_alpha * wiener_gain_smooth(:,t_idx-1) ...
                                    + (1 - smooth_alpha) * wiener_gain(:,t_idx);
    end
    wiener_gain = max(wiener_gain_smooth, beta);
    mag_clean = wiener_gain .* mag;
    S_clean = mag_clean .* exp(1j * phase);
    y = istft(S_clean, fs, 'Window', win, ...
              'OverlapLength', frame_len-hop, 'FFTLength', frame_len);
    if length(y) < length(x)
        y = [y; zeros(length(x) - length(y), 1)];
    else
        y = y(1:length(x));
    end
    y = real(y);
    y = y / (max(abs(y)) + 1e-12);
    energy = zeros(num_frames, 1); zcr = zeros(num_frames, 1);
    for i = 1:num_frames
        idx = (i-1)*hop + 1;
        frame = x(idx : min(idx + frame_len - 1, length(x)));
        energy(i) = sum(frame.^2) / length(frame);
        zcr(i) = sum(abs(diff(sign(frame)))) / (2 * length(frame));
    end
    info = struct('is_noise_frame', is_noise_frame, 'energy', energy, 'zcr', zcr, ...
                  'energy_thresh', energy_thresh, 'zcr_thresh', 0, ...
                  'frame_len', frame_len, 'hop', hop, 'num_frames', num_frames);
end

% --- enhance_clarity.m ---
function y = enhance_clarity(x, fs)
    % Frequency-domain speech enhancement:
    %   Stage A: Pre-emphasis
    %   Stage B: Spectral tilt (boost 300-3400 Hz)
    %   Stage C: Per-band dynamic boost
    %   Stage D: Peak normalization + safety
    
    x = real(x);   % Safety
    
    % ---- Stage A: Pre-emphasis ----
    pre_emph = 0.97;
    x_pre = filter([1, -pre_emph], 1, x);
    
    % ---- Stage B: Spectral tilt ----
    N = length(x_pre);
    X = fft(x_pre);
    f_axis = (0:N-1)' * (fs/N);
    f_axis(f_axis > fs/2) = f_axis(f_axis > fs/2) - fs;
    f_abs = abs(f_axis);
    
    gain_curve = zeros(N, 1);
    for k = 1:N
        f = f_abs(k);
        if f < 100
            gain_curve(k) = 10^(-6/20);
        elseif f < 300
            gain_curve(k) = 10^(0/20);
        elseif f < 1000
            gain_curve(k) = 10^(3/20);
        elseif f < 3400
            gain_curve(k) = 10^(6/20);
        else
            gain_curve(k) = 10^(3/20);
        end
    end
    
    smooth_win = round(0.010 * fs);
    gain_curve = movmean(gain_curve, smooth_win);
    
    X_tilt = X .* gain_curve;
    x_tilt = real(ifft(X_tilt));
    
    % ---- Stage C: Per-band dynamic boost ----
    fl = round(0.025*fs);
    hl = round(0.015*fs);
    [S, ~, ~] = stft(x_tilt, fs, 'Window', hamming(fl, 'periodic'), ...
                     'OverlapLength', hl, 'FFTLength', fl);
    mag = abs(S); phase = angle(S);
    
    band_power = mean(mag.^2, 2) + 1e-12;
    band_power_db = 10*log10(band_power);
    target_db = max(band_power_db) - 12;
    band_boost_db = max(0, target_db - band_power_db);
    band_boost_db = min(band_boost_db, 6);
    band_boost = 10.^(band_boost_db / 20);
    
    mag_boosted = mag .* band_boost;
    S_boosted = mag_boosted .* exp(1j * phase);
    
    x_boost = istft(S_boosted, fs, 'Window', hamming(fl, 'periodic'), ...
                    'OverlapLength', hl, 'FFTLength', fl);
    
    if length(x_boost) < length(x)
        x_boost = [x_boost; zeros(length(x) - length(x_boost), 1)];
    else
        x_boost = x_boost(1:length(x));
    end
    
    % ---- Stage D: Force real, normalize, safety clip ----
    x_boost = real(x_boost);          % <-- CRITICAL FIX
    
    peak = max(abs(x_boost));
    if peak > 0
        y = x_boost * (0.95 / peak);
    else
        y = x_boost;
    end
    
    y = real(y);                      % <-- CRITICAL FIX
    y = max(min(y, 1), -1);
    y = double(y);                    % <-- Ensure float type
end
