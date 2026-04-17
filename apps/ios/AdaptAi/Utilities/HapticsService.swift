import Foundation
import CoreHaptics
import UIKit
import AdaptAiKit


@Observable
final class HapticsService {
    static let shared = HapticsService()

    private var engine: CHHapticEngine?

    init() {
        prepareEngine()
    }

    private func prepareEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            engine?.resetHandler = { [weak self] in
                try? self?.engine?.start()
            }
            try engine?.start()
        } catch {
            print("HapticsService: Failed to start engine: \(error)")
        }
    }

    // Simple feedback using UIKit
    func lightTap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func mediumTap() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func heavyTap() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    // Custom haptic pattern for stall re-prompt (gentle pulsing)
    func stallRePrompt() {
        guard let engine else { return }
        do {
            let pattern = try CHHapticPattern(events: [
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3),
                    ],
                    relativeTime: 0
                ),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5),
                    ],
                    relativeTime: 0.3
                ),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7),
                    ],
                    relativeTime: 0.6
                ),
            ], parameters: [])

            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            // Fallback to simple haptic
            warning()
        }
    }

    // Emergency SOS pattern
    func emergencyPulse() {
        guard let engine else {
            heavyTap()
            return
        }
        do {
            var events: [CHHapticEvent] = []
            for i in 0..<5 {
                events.append(CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0),
                    ],
                    relativeTime: Double(i) * 0.15
                ))
            }
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            heavyTap()
        }
    }
}
