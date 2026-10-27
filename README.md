# MATLAB Speech Denoising and Enhancement

A Digital Signal Processing (DSP) mini-project that demonstrates speech denoising and speech clarity enhancement using MATLAB. The system captures speech through a live microphone, introduces synthetic background noise, applies multiple signal-processing stages, and compares the resulting audio signals in both the time and frequency domains.

## Overview

Speech recordings can contain background noise that reduces intelligibility. This project implements a multi-stage processing pipeline to reduce noise and enhance speech clarity.

The system combines linear filtering, Wiener filtering, and frequency-domain spectral enhancement. It also generates plots to help visualize how each stage affects the speech signal.

## Features

- **Live Speech Recording:** Records six seconds of mono speech using a microphone at a sampling frequency of 16 kHz.
- **Synthetic Noise Generation:** Adds white Gaussian noise at a nominal 10 dB SNR, along with simulated keyboard clicks.
- **Linear Filtering:** Applies a notch filter and a low-pass Butterworth filter to the noisy recording.
- **Wiener Filtering:** Estimates noise power from the quietest 15% of time-frequency frames and applies a frequency-dependent Wiener gain.
- **Spectral Enhancement:** Uses pre-emphasis, frequency-dependent spectral gain, and adaptive per-band boosting to enhance speech clarity.
- **Audio Playback:** Plays the noisy, denoised, and enhanced signals for subjective comparison.
- **Signal Visualization:** Produces plots of the processing pipeline, frequency spectra, spectral gain differences, and frame-level noise detection.

## Signal Processing Pipeline

The system follows this sequence:

1. Record clean speech through the microphone.
2. Normalize the recorded signal.
3. Add synthetic Gaussian noise and keyboard-click disturbances.
4. Apply notch and low-pass filtering.
5. Perform STFT-based Wiener filtering.
6. Enhance speech using pre-emphasis and frequency-domain gain adjustments.
7. Play the processed signals and generate comparison plots.

**Pipeline summary:**

`Microphone Input → Synthetic Noise → Linear Filtering → Wiener Filtering → Spectral Enhancement → Playback and Analysis`

## Technologies Used

- MATLAB
- Digital Signal Processing
- Short-Time Fourier Transform (STFT)
- Wiener filtering
- IIR notch filtering
- Butterworth low-pass filtering
- Spectral gain adjustment
- Time-domain and frequency-domain analysis

## Requirements

- MATLAB installed on your computer.
- A working microphone and audio output device.
- MATLAB functions and toolboxes supporting the signal-processing operations used in the script. Depending on your MATLAB release and installation, functions such as `stft`, `istft`, `iirnotch`, `butter`, and `filtfilt` may require the relevant Signal Processing Toolbox functionality.

## How to Run

1. Clone or download this repository.
2. Open MATLAB.
3. Navigate to the folder containing the project script.
4. Run the main `.m` file.
5. Allow microphone access if prompted.
6. Speak naturally during the six-second recording.
7. Listen to the noisy, denoised, and enhanced audio outputs.
8. Inspect the generated figures to compare the signals.

The script generates three main analysis figures:

- **Full Pipeline Analysis:** Compares the original recording, noisy signal, linearly filtered signal, Wiener-filtered signal, and final enhanced signal.
- **Spectrum Comparison:** Shows the frequency spectra before and after enhancement, along with the change in magnitude across frequencies.
- **Noise Frame Detection:** Visualizes the frames selected as noise, short-term energy, and zero-crossing rate.

## Parameters

| Parameter | Value |
|---|---:|
| Sampling frequency | 16,000 Hz |
| Recording duration | 6 seconds |
| Audio format | 16-bit mono recording |
| Synthetic Gaussian noise SNR | 10 dB nominal |
| Notch frequency | 50 Hz |
| Low-pass cutoff frequency | 3,400 Hz |
| Wiener-filter gain floor | 0.02 |
| Frame duration for Wiener filtering | 25 ms |
| Frame hop for Wiener filtering | 10 ms |
| Noise-frame selection | Quietest 15% of frames |

These values are defined in the current script and can be modified for experimentation.

## Results and Evaluation

The project provides both audio playback and graphical analysis for comparing the signal at different processing stages.

The plots help examine changes in waveform amplitude, frequency content, and the frame-level characteristics used for noise estimation. Listening tests provide a qualitative comparison of the original noisy signal and the processed outputs.

The current implementation is primarily a demonstration and comparative analysis of speech enhancement techniques. Its effectiveness can vary depending on the speaker, recording environment, and type of noise. The code does not, by itself, establish a measured improvement in intelligibility or a guaranteed increase in speech quality.

## Limitations

- Noise is simulated in software rather than captured from a separate real-world noise recording.
- The Wiener filter estimates noise using the quietest portion of the analyzed frames; these frames may still contain speech.
- Spectral boosting may also amplify residual noise or introduce artifacts.
- Playback quality and perceived clarity depend on the microphone, audio output device, and recording conditions.
- Objective evaluation metrics are not currently included.

## Future Improvements

- Test the system with real-world background-noise recordings.
- Compare multiple noise-reduction algorithms.
- Measure signal-to-noise ratio before and after processing.
- Add objective speech-quality metrics such as segmental SNR and, where suitable, PESQ or STOI.
- Evaluate performance under different noise levels and speech conditions.
- Add configurable parameters for recording duration, noise level, and enhancement strength.

## Learning Outcomes

This project explores practical applications of DSP, including noise modeling, digital filtering, short-time spectral analysis, Wiener filtering, and frequency-domain signal enhancement. It also demonstrates how plots and listening tests can be used together to study the behavior of a signal-processing pipeline.

## Author

Aryaman Jha (along with Joahan Ashish & Aniket Jaiswar)

Electronics and Telecommunication Engineering, SPIT MUMBAI

This project is available for educational and learning purposes and for curious learners :)
