import SwiftUI
#if canImport(AVFoundation)
import AVFoundation
#endif

struct Diag_RecordingTestView: View {
    @State private var audioRecorder: AVAudioRecorder?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isRecording = false
    @State private var isPlaying = false
    @State private var hasRecording = false
    @State private var recordingDuration: TimeInterval = 0
    @State private var timer: Timer?

    private let recordingURL = FileManager.default.temporaryDirectory.appendingPathComponent("diag_recording_test.m4a")

    var body: some View {
        Form {
            Section("Recording") {
                VStack(spacing: 16) {
                    Image(systemName: isRecording ? "waveform.circle.fill" : "waveform.circle")
                        .font(.system(size: 60))
                        .foregroundStyle(isRecording ? .red : .blue)
                        .symbolEffect(.pulse, isActive: isRecording)

                    if isRecording {
                        Text(formatTime(recordingDuration))
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                            .foregroundStyle(.red)
                    } else if hasRecording {
                        Text("Recording saved")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                    } else {
                        Text("Tap record to begin")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section {
                Button {
                    if isRecording { stopRecording() } else { startRecording() }
                } label: {
                    HStack {
                        Image(systemName: isRecording ? "stop.circle.fill" : "record.circle")
                            .foregroundStyle(.red)
                        Text(isRecording ? "Stop Recording" : "Start Recording")
                    }
                }
                .disabled(isPlaying)
            }

            if hasRecording {
                Section("Playback") {
                    Button {
                        if isPlaying { stopPlayback() } else { startPlayback() }
                    } label: {
                        HStack {
                            Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                                .foregroundStyle(.blue)
                            Text(isPlaying ? "Stop Playback" : "Play Recording")
                        }
                    }
                    .disabled(isRecording)

                    Button("Delete Recording", role: .destructive) {
                        deleteRecording()
                    }
                }
            }

            Section {
                Text("Record a short audio clip and play it back to verify microphone and speaker functionality.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Recording Test")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            stopRecording()
            stopPlayback()
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let mins = Int(time) / 60
        let secs = Int(time) % 60
        let ms = Int((time.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%d", mins, secs, ms)
    }

    private func startRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch { return }

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        guard let recorder = try? AVAudioRecorder(url: recordingURL, settings: settings) else { return }
        recorder.record()
        audioRecorder = recorder
        isRecording = true
        recordingDuration = 0

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            recordingDuration += 0.1
        }
    }

    private func stopRecording() {
        timer?.invalidate()
        timer = nil
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        hasRecording = FileManager.default.fileExists(atPath: recordingURL.path)
    }

    private func startPlayback() {
        guard let player = try? AVAudioPlayer(contentsOf: recordingURL) else { return }
        player.play()
        audioPlayer = player
        isPlaying = true
        DispatchQueue.main.asyncAfter(deadline: .now() + player.duration + 0.1) {
            isPlaying = false
        }
    }

    private func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
    }

    private func deleteRecording() {
        try? FileManager.default.removeItem(at: recordingURL)
        hasRecording = false
    }
}
