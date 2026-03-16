import Foundation
import CoreMotion
import UIKit
import NeuroNavKit

@Observable
final class CrashDetectionService {
    static let shared = CrashDetectionService()

    var isMonitoring = false
    var lastImpactDate: Date?
    var showingCountdown = false
    var countdownSeconds = 30

    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()
    private let impactThreshold = 3.5 // g-force threshold
    private var countdownTimer: Timer?
    private var onEmergencyTrigger: (() -> Void)?

    init() {
        queue.name = "com.neuronav.crashdetection"
        queue.maxConcurrentOperationCount = 1
    }

    func startMonitoring(onEmergency: @escaping () -> Void) {
        guard motionManager.isAccelerometerAvailable else { return }
        onEmergencyTrigger = onEmergency

        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: queue) { [weak self] data, _ in
            guard let self, let data else { return }

            let x = data.acceleration.x
            let y = data.acceleration.y
            let z = data.acceleration.z
            let totalG = sqrt(x * x + y * y + z * z)

            if totalG > self.impactThreshold {
                DispatchQueue.main.async {
                    self.handleImpactDetected()
                }
            }
        }

        isMonitoring = true
    }

    func stopMonitoring() {
        motionManager.stopAccelerometerUpdates()
        cancelCountdown()
        isMonitoring = false
    }

    private func handleImpactDetected() {
        // Debounce: ignore if less than 60 seconds since last
        if let last = lastImpactDate, Date().timeIntervalSince(last) < 60 { return }

        lastImpactDate = Date()
        countdownSeconds = 30
        showingCountdown = true

        // Send notification
        NotificationService.shared.sendFallDetectionAlert()

        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }

            self.countdownSeconds -= 1

            if self.countdownSeconds <= 0 {
                timer.invalidate()
                self.triggerEmergencyCall()
            }
        }

        // Haptic alert
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    func cancelCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        showingCountdown = false
        countdownSeconds = 30
    }

    private func triggerEmergencyCall() {
        showingCountdown = false
        onEmergencyTrigger?()
        callPrimaryContact()
    }

    func callPrimaryContact() {
        Task { @MainActor in
            do {
                let contacts = try await APIClient.shared.fetchEmergencyContacts()
                guard let primary = contacts.first(where: { $0.isPrimary }) ?? contacts.first,
                      let url = URL(string: "tel://\(primary.phone)") else { return }

                let msg = "Se detectó un impacto fuerte. El usuario no desactivó la alerta en 30 segundos. Llamando a \(primary.name)."

                try await APIClient.shared.createAlert(
                    type: .crashDetected,
                    severity: .critical,
                    title: "Caída detectada",
                    message: msg
                )

                // Notify all linked family members/caregivers
                try? await APIClient.shared.notifyFamilyMembers(
                    alertType: .crashDetected,
                    title: "Caída detectada",
                    message: msg
                )

                await UIApplication.shared.open(url)
            } catch {
                print("CrashDetection: error calling contact: \(error)")
            }
        }
    }
}
