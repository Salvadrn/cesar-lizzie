import Foundation
import ActivityKit

struct RoutineActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        let currentStepIndex: Int
        let totalSteps: Int
        let currentStepTitle: String
        let isStalled: Bool
    }

    let routineTitle: String
    let routineCategory: String
}
