import SwiftUI
import AVKit
import AVFoundation

/// Displays video or audio media attached to a routine step.
/// - Video: inline AVKit VideoPlayer at 16:9 aspect ratio
/// - Audio-only: circular play/pause button with pulsing animation
/// - Neither: EmptyView
struct StepMediaPlayerView: View {
    let audioURL: String?
    let videoURL: String?
    let autoPlay: Bool // true for complexity levels 1-2

    // MARK: - Video state

    @State private var videoPlayer: AVPlayer?

    // MARK: - Audio state

    @State private var audioPlayer: AVPlayer?
    @State private var isPlayingAudio = false
    @State private var audioTimeObserver: Any?

    var body: some View {
        if let videoURLString = videoURL, let url = URL(string: videoURLString) {
            videoPlayerView(url: url)
        } else if let audioURLString = audioURL, let url = URL(string: audioURLString) {
            audioPlayerView(url: url)
        }
        // If neither URL is present, body produces EmptyView implicitly
    }

    // MARK: - Video Player

    @ViewBuilder
    private func videoPlayerView(url: URL) -> some View {
        let player = makeVideoPlayer(url: url)

        VideoPlayer(player: player)
            .aspectRatio(16 / 9, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.nnRule, lineWidth: 1)
            )
            .onAppear {
                if autoPlay {
                    player.play()
                }
            }
            .onDisappear {
                player.pause()
            }
    }

    // MARK: - Audio Player

    @ViewBuilder
    private func audioPlayerView(url: URL) -> some View {
        VStack(spacing: 16) {
            ZStack {
                // Pulsing ring while playing
                if isPlayingAudio {
                    Circle()
                        .stroke(Color.nnPrimary.opacity(0.3), lineWidth: 4)
                        .frame(width: 88, height: 88)
                        .scaleEffect(isPlayingAudio ? 1.25 : 1.0)
                        .opacity(isPlayingAudio ? 0.0 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.2).repeatForever(autoreverses: false),
                            value: isPlayingAudio
                        )

                    Circle()
                        .stroke(Color.nnPrimary.opacity(0.2), lineWidth: 3)
                        .frame(width: 88, height: 88)
                        .scaleEffect(isPlayingAudio ? 1.5 : 1.0)
                        .opacity(isPlayingAudio ? 0.0 : 0.8)
                        .animation(
                            .easeInOut(duration: 1.2).repeatForever(autoreverses: false).delay(0.4),
                            value: isPlayingAudio
                        )
                }

                // Play / Pause button
                Button {
                    toggleAudio(url: url)
                } label: {
                    Circle()
                        .fill(Color.nnPrimary)
                        .frame(width: 72, height: 72)
                        .overlay(
                            Image(systemName: isPlayingAudio ? "pause.fill" : "play.fill")
                                .font(.title)
                                .foregroundStyle(.white)
                                .offset(x: isPlayingAudio ? 0 : 2) // optical centering for play icon
                        )
                        .shadow(color: Color.nnPrimary.opacity(0.3), radius: 6, y: 3)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isPlayingAudio ? "Pausar audio" : "Reproducir audio")
            }

            // Waveform bars
            HStack(spacing: 3) {
                ForEach(0..<12, id: \.self) { index in
                    WaveformBar(isAnimating: isPlayingAudio, index: index)
                }
            }
            .frame(height: 28)

            Text(isPlayingAudio ? "Reproduciendo..." : "Audio disponible")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .onAppear {
            if autoPlay {
                toggleAudio(url: url)
            }
        }
        .onDisappear {
            stopAudio()
        }
    }

    // MARK: - Audio Helpers

    private func toggleAudio(url: URL) {
        if isPlayingAudio {
            audioPlayer?.pause()
            isPlayingAudio = false
        } else {
            if audioPlayer == nil {
                let player = AVPlayer(url: url)
                audioPlayer = player

                // Observe end of playback
                NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: player.currentItem,
                    queue: .main
                ) { _ in
                    isPlayingAudio = false
                    player.seek(to: .zero)
                }
            }
            audioPlayer?.seek(to: .zero)
            audioPlayer?.play()
            isPlayingAudio = true
        }
    }

    private func stopAudio() {
        audioPlayer?.pause()
        audioPlayer = nil
        isPlayingAudio = false
    }

    // MARK: - Video Helper

    private func makeVideoPlayer(url: URL) -> AVPlayer {
        if let existing = videoPlayer { return existing }
        let player = AVPlayer(url: url)
        // Store via DispatchQueue to avoid mutating @State during view update
        DispatchQueue.main.async { videoPlayer = player }
        return player
    }
}

// MARK: - Waveform Bar

private struct WaveformBar: View {
    let isAnimating: Bool
    let index: Int

    @State private var height: CGFloat = 6

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.nnPrimary.opacity(isAnimating ? 0.8 : 0.3))
            .frame(width: 4, height: height)
            .onChange(of: isAnimating, initial: true) { _, playing in
                if playing {
                    startAnimation()
                } else {
                    withAnimation(.easeOut(duration: 0.3)) { height = 6 }
                }
            }
    }

    private func startAnimation() {
        let delay = Double(index) * 0.08
        withAnimation(
            .easeInOut(duration: 0.4 + Double.random(in: 0...0.3))
            .repeatForever(autoreverses: true)
            .delay(delay)
        ) {
            height = CGFloat.random(in: 10...28)
        }
    }
}
