import Foundation
import WatchConnectivity


struct WatchRoutine: Codable, Identifiable {
    let id: String
    let title: String
    let category: String
    let stepsCount: Int
    let steps: [WatchStep]
}

struct WatchStep: Codable, Identifiable {
    let id: String
    let title: String
    let instruction: String
    let durationHint: Int
}

@Observable
final class WatchConnectivityManager: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()

    var todayRoutines: [WatchRoutine] = []
    var completedRoutineIds: Set<String> = []
    var isReachable = false
    var lastSyncDate: Date?

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    // MARK: - Send to iPhone

    func requestTodayRoutines() {
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(["action": "requestRoutines"], replyHandler: { response in
            if let data = response["routines"] as? Data {
                let routines = try? JSONDecoder().decode([WatchRoutine].self, from: data)
                Task { @MainActor in
                    self.todayRoutines = routines ?? []
                    self.lastSyncDate = .now
                }
            }
        }, errorHandler: nil)
    }

    func reportStepCompletion(routineId: String, stepId: String) {
        let message: [String: Any] = [
            "action": "stepCompleted",
            "routineId": routineId,
            "stepId": stepId,
        ]
        WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: nil)
    }

    func triggerEmergency() {
        let message: [String: Any] = [
            "action": "emergency",
        ]
        WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: nil)
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            isReachable = session.isReachable
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let data = message["routinesUpdate"] as? Data {
            let routines = try? JSONDecoder().decode([WatchRoutine].self, from: data)
            Task { @MainActor in
                self.todayRoutines = routines ?? []
            }
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isReachable = session.isReachable
        }
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) { }
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif
}
