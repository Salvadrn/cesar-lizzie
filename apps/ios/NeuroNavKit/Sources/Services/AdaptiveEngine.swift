import Foundation

// Flutter equivalent: adaptive_engine.dart (pure logic, easily portable)

@Observable
public final class AdaptiveEngine {
    public static let shared = AdaptiveEngine()

    public var currentLevel: Int = 3

    public func computeRawScore(metrics: AdaptiveMetrics) -> Int {
        var score = 3

        // Error rate adjustments
        if metrics.errorRate > 0.4 { score -= 2 }
        else if metrics.errorRate > 0.25 { score -= 1 }
        else if metrics.errorRate < 0.05 { score += 1 }

        // Response time adjustments (milliseconds)
        if metrics.avgResponseTime > 8000 { score -= 1 }
        else if metrics.avgResponseTime < 2000 { score += 1 }

        // Task completion rate adjustments
        if metrics.taskCompletionRate < 0.5 { score -= 1 }
        else if metrics.taskCompletionRate > 0.9 { score += 1 }

        // Stall rate adjustment
        if metrics.stallRate > 0.3 { score -= 1 }

        // Tap accuracy adjustment (pixels of deviation)
        if metrics.tapAccuracy > 50 { score -= 1 }

        return max(1, min(5, score))
    }

    public func smoothLevel(
        current: Double,
        computed: Int,
        floor: Int,
        ceiling: Int
    ) -> Int {
        // Exponential moving average: alpha = 0.3
        let smoothed = 0.7 * current + 0.3 * Double(computed)
        let rounded = Int(smoothed.rounded())

        // Clamp to caregiver-set floor and ceiling
        let clamped = max(floor, min(ceiling, rounded))

        // Max +-1 change per session
        let maxDelta = 1
        let delta = clamped - Int(current)
        let constrainedDelta = max(-maxDelta, min(maxDelta, delta))

        return Int(current) + constrainedDelta
    }

    public func recalculate(
        metrics: AdaptiveMetrics,
        currentLevel: Double,
        floor: Int,
        ceiling: Int
    ) -> Int {
        let rawScore = computeRawScore(metrics: metrics)
        let newLevel = smoothLevel(
            current: currentLevel,
            computed: rawScore,
            floor: floor,
            ceiling: ceiling
        )
        self.currentLevel = newLevel
        return newLevel
    }

    public func levelConfig() -> ComplexityLevelConfig {
        ComplexityLevels.config(for: currentLevel)
    }
}
