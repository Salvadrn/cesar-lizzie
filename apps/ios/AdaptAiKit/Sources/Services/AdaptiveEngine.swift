import Foundation


/// Holds the current adaptive complexity level and provides UI configuration.
/// The level is computed server-side (adaptive.service.ts) and synced to the client.
/// This class no longer duplicates the computation logic — it only consumes the result.
@Observable
public final class AdaptiveEngine {
    public static let shared = AdaptiveEngine()

    public var currentLevel: Int = 3

    private init() {}

    /// Updates the level from a server-provided value (e.g. after profile fetch).
    public func updateFromServer(level: Int) {
        currentLevel = max(1, min(5, level))
    }

    /// Returns the UI config for the current complexity level.
    public func levelConfig() -> ComplexityLevelConfig {
        ComplexityLevels.config(for: currentLevel)
    }
}
