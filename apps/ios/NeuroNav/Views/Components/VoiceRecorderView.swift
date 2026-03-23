import SwiftUI
import AVFoundation

/// Reusable voice recorder for caregivers to record audio instructions.
/// Records up to 60 seconds of AAC audio (.m4a), provides playback,
/// and returns the recorded data via `onSave`.
struct VoiceRecorderView: View {
    let onSave: (Data) -> Void
    let onCancel: () -> Void

    // MARK: - Recording state

    @State private var audioRecorder: AVAudioRecorder?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isRecording = false
    @State private var isPlaying = false
    @State private var recordingTime: TimeInterval = 0
    @State private var audioLevel: Float = 0
    @State private var hasRecording = false

    @State private var timerTask: Task<Void, Never>?
    @State private var levelTimer: Task<Void, Never>?

    private let maxDuration: TimeInterval = 60

    var body: some View {
        VStack(spacing: 24) {
            // Header
            Text("Grabar instruccion de voz")
                .font(.headline)
                .foregroundStyle(.primary)

            // Timer
            Text(formattedTime)
                .font(.system(size: 48, weight: .light, design: .monospaced))
                .foregroundStyle(isRecording ? .nnError : .primary)
                .contentTransition(.numericText())

            // Level indicator
            levelIndicator
                .frame(height: 40)
                .padding(.horizontal)

            // Remaining time indicator
            if isRecording {
                Text("Maximo: \(Int(maxDuration - recordingTime))s restantes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Controls
            HStack(spacing: 40) {
                // Cancel
                Button {
                    cleanup()
                    onCancel()
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .frame(width: 48, height: 48)
                            .background(Color(.systemGray5))
                            .clipShape(Circle())
                        Text("Cancelar")
                            .font(.caption2)
                    }
                }
                .foregroundStyle(.secondary)

                // Record / Stop
                Button {
                    if isRecording {
                        stopRecording()
                    } else if hasRecording {
                        // Re-record — discard previous
                        hasRecording = false
                        audioPlayer = nil
                        startRecording()
                    } else {
                        startRecording()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(isRecording ? .nnError : Color(.systemGray5))
                            .frame(width: 80, height: 80)

                        if isRecording {
                            // Stop icon (rounded square)
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.white)
                                .frame(width: 28, height: 28)
                        } else {
                            Circle()
                                .fill(.nnError)
                                .frame(width: hasRecording ? 28 : 60, height: hasRecording ? 28 : 60)
                        }
                    }
                    .shadow(color: isRecording ? Color.nnError.opacity(0.4) : .clear, radius: 8, y: 2)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isRecording ? "Detener grabacion" : "Iniciar grabacion")

                // Play / Save
                if hasRecording && !isRecording {
                    Button {
                        if isPlaying {
                            stopPlayback()
                        } else {
                            playRecording()
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                                .font(.title3)
                                .frame(width: 48, height: 48)
                                .background(Color.nnPrimary.opacity(0.15))
                                .foregroundStyle(.nnPrimary)
                                .clipShape(Circle())
                            Text(isPlaying ? "Detener" : "Escuchar")
                                .font(.caption2)
                        }
                    }
                    .foregroundStyle(.nnPrimary)
                } else {
                    // Invisible placeholder to keep layout balanced
                    Color.clear
                        .frame(width: 48, height: 48)
                }
            }

            // Save button
            if hasRecording && !isRecording {
                Button {
                    saveRecording()
                } label: {
                    Text("Guardar grabacion")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.nnPrimary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 24)
        .onDisappear {
            cleanup()
        }
    }

    // MARK: - Level Indicator

    @ViewBuilder
    private var levelIndicator: some View {
        HStack(spacing: 2) {
            ForEach(0..<24, id: \.self) { index in
                let threshold = Float(index) / 24.0
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(barColor(for: index, active: audioLevel > threshold))
                    .frame(width: 6)
                    .scaleEffect(y: audioLevel > threshold ? 1.0 : 0.3, anchor: .bottom)
                    .animation(.easeOut(duration: 0.1), value: audioLevel)
            }
        }
    }

    private func barColor(for index: Int, active: Bool) -> Color {
        guard active else { return Color(.systemGray4) }
        let ratio = Float(index) / 24.0
        if ratio < 0.6 {
            return .nnPrimary
        } else if ratio < 0.85 {
            return .nnWarning
        } else {
            return .nnError
        }
    }

    // MARK: - Formatted Time

    private var formattedTime: String {
        let minutes = Int(recordingTime) / 60
        let seconds = Int(recordingTime) % 60
        return String(format: "%01d:%02d", minutes, seconds)
    }

    // MARK: - Recording

    private func startRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            print("VoiceRecorder: Error configurando sesion de audio: \(error.localizedDescription)")
            return
        }

        let url = recordingFileURL()

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            let recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder.isMeteringEnabled = true
            recorder.record()
            audioRecorder = recorder
            isRecording = true
            recordingTime = 0
            startTimers()
        } catch {
            print("VoiceRecorder: Error creando grabador: \(error.localizedDescription)")
        }
    }

    private func stopRecording() {
        cancelTimers()
        audioRecorder?.stop()
        isRecording = false
        hasRecording = true
    }

    // MARK: - Playback

    private func playRecording() {
        let url = recordingFileURL()
        guard FileManager.default.fileExists(atPath: url.path) else { return }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.play()
            audioPlayer = player
            isPlaying = true

            // Monitor playback end
            Task { @MainActor in
                // Poll until done — AVAudioPlayer delegates require NSObject
                while audioPlayer?.isPlaying == true {
                    try? await Task.sleep(for: .milliseconds(200))
                }
                isPlaying = false
            }
        } catch {
            print("VoiceRecorder: Error reproduciendo: \(error.localizedDescription)")
        }
    }

    private func stopPlayback() {
        audioPlayer?.stop()
        isPlaying = false
    }

    // MARK: - Save

    private func saveRecording() {
        stopPlayback()
        let url = recordingFileURL()
        guard let data = try? Data(contentsOf: url) else { return }
        onSave(data)
    }

    // MARK: - Timers

    private func startTimers() {
        timerTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard isRecording else { continue }
                recordingTime += 1
                if recordingTime >= maxDuration {
                    stopRecording()
                    return
                }
            }
        }

        levelTimer = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard isRecording, let recorder = audioRecorder else { continue }
                recorder.updateMeters()
                let power = recorder.averagePower(forChannel: 0) // -160 to 0
                // Normalize to 0...1
                let normalized = max(0, min(1, (power + 50) / 50))
                audioLevel = normalized
            }
        }
    }

    private func cancelTimers() {
        timerTask?.cancel()
        timerTask = nil
        levelTimer?.cancel()
        levelTimer = nil
        audioLevel = 0
    }

    // MARK: - File URL

    private func recordingFileURL() -> URL {
        let temp = FileManager.default.temporaryDirectory
        return temp.appendingPathComponent("nn_voice_recording.m4a")
    }

    // MARK: - Cleanup

    private func cleanup() {
        cancelTimers()
        audioRecorder?.stop()
        audioPlayer?.stop()
        audioRecorder = nil
        audioPlayer = nil
        isRecording = false
        isPlaying = false
        // Remove temp file
        try? FileManager.default.removeItem(at: recordingFileURL())
    }
}
