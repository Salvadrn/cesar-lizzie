import SwiftUI
import SwiftData
import NeuroNavKit

@main
struct NeuroNavApp: App {
    @State private var authService = AuthService.shared
    @State private var adaptiveEngine = AdaptiveEngine.shared
    @State private var speechService = SpeechService.shared
    @State private var hapticsService = HapticsService.shared
    @State private var locationService = LocationService.shared
    @State private var notificationService = NotificationService.shared
    @State private var syncService = SyncService.shared
    @State private var crashDetection = CrashDetectionService.shared
    @State private var claudeService = ClaudeService.shared
    @State private var smartNotifications = SmartNotificationService.shared

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            NNUser.self,
            NNUserProfile.self,
            NNRoutine.self,
            NNRoutineStep.self,
            NNRoutineExecution.self,
            NNStepExecution.self,
            NNSafetyZone.self,
            NNEmergencyContact.self,
            NNAlert.self,
            NNCaregiverLink.self,
            NNMoodEntry.self,
            NNAchievement.self,
            NNUserStats.self,
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(AppConstants.appGroupIdentifier)
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    private var dynamicTypeSize: DynamicTypeSize {
        let scale = authService.currentProfile?.fontScale ?? 1.0
        switch scale {
        case ..<0.85: return .xSmall
        case 0.85..<0.95: return .small
        case 0.95..<1.05: return .medium
        case 1.05..<1.15: return .large
        case 1.15..<1.25: return .xLarge
        case 1.25..<1.35: return .xxLarge
        case 1.35..<1.45: return .xxxLarge
        default: return .accessibility1
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authService)
                .environment(adaptiveEngine)
                .environment(speechService)
                .environment(hapticsService)
                .environment(locationService)
                .environment(notificationService)
                .environment(syncService)
                .dynamicTypeSize(dynamicTypeSize)
        }
        .modelContainer(sharedModelContainer)
    }
}
