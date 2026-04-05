import SwiftUI
import NeuroNavKit

struct ContentView: View {
    @Environment(AuthService.self) private var authService
    @State private var isLoading = true
    @State private var showComplexityQuiz = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Cargando...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if authService.isGuestMode {
                if authService.isSimpleModeActive {
                    SimpleModeTabView()
                } else {
                    MainTabView()
                }
            } else if authService.isAuthenticated {
                if needsOnboarding {
                    OnboardingView()
                        .environment(authService)
                } else if showComplexityQuiz {
                    ComplexityQuizView {
                        showComplexityQuiz = false
                        UserDefaults.standard.set(true, forKey: "complexity_quiz_shown")
                    }
                } else if authService.isSimpleModeActive {
                    SimpleModeTabView()
                } else {
                    MainTabView()
                }
            } else {
                LoginView()
            }
        }
        .task {
            await authService.restoreSession()
            isLoading = false
        }
        .onChange(of: needsOnboarding) { _, newValue in
            // After onboarding completes, suggest complexity quiz for patients
            if !newValue,
               authService.currentProfile?.role == "patient",
               !UserDefaults.standard.bool(forKey: "complexity_quiz_shown") {
                showComplexityQuiz = true
            }
        }
    }

    private var needsOnboarding: Bool {
        guard let profile = authService.currentProfile else { return true }
        return profile.displayName.isEmpty
    }

}

struct MainTabView: View {
    @Environment(AuthService.self) private var authService
    @Environment(AdaptiveEngine.self) private var engine
    @State private var crashService = CrashDetectionService.shared
    @State private var showGuestSignUp = false

    private var role: AppConstants.UserRole {
        authService.currentRole
    }

    private var level: Int { engine.currentLevel }

    var body: some View {
        ZStack {
            TabView {
                NavigationStack {
                    AdaptiveHomeView()
                }
                .tabItem {
                    Label("Inicio", systemImage: "house.fill")
                }

                // Level 1: only Inicio + Emergencia (routines/meds accessible from home)
                // Level 2: Inicio + Medicamentos + Emergencia + Ajustes
                // Level 3+: all tabs

                if level >= 3 && role != .family {
                    NavigationStack {
                        RoutineListView()
                    }
                    .tabItem {
                        Label("Rutinas", systemImage: "list.bullet.clipboard.fill")
                    }
                }

                if level >= 2 {
                    NavigationStack {
                        MedicationView()
                    }
                    .tabItem {
                        Label("Medicamentos", systemImage: "pills.fill")
                    }
                }

                if level >= 2 {
                    NavigationStack {
                        HealthView()
                    }
                    .tabItem {
                        Label("Salud", systemImage: "heart.text.clipboard")
                    }
                }

                if level >= 3 {
                    NavigationStack {
                        FamilyView()
                    }
                    .tabItem {
                        Label("Familia", systemImage: "person.2.fill")
                    }
                }

                NavigationStack {
                    EmergencyView()
                }
                .tabItem {
                    Label("Emergencia", systemImage: "sos.circle.fill")
                }

                if level >= 2 {
                    NavigationStack {
                        SettingsView()
                    }
                    .tabItem {
                        Label("Ajustes", systemImage: "gearshape.fill")
                    }
                }
            }
            .tint(.nnPrimary)

            // Crash detection overlay
            CrashCountdownOverlay(crashService: crashService)
                .animation(.easeInOut, value: crashService.showingCountdown)
        }
        .safeAreaInset(edge: .top) {
            if authService.isGuestMode {
                Button {
                    showGuestSignUp = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.caption)
                        Text("Modo invitado — Crear cuenta")
                            .font(.caption.bold())
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                }
                .tint(.primary)
            }
        }
        .sheet(isPresented: $showGuestSignUp) {
            NavigationStack {
                LoginView()
                    .navigationTitle("Crear cuenta")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cerrar") { showGuestSignUp = false }
                        }
                    }
            }
            .environment(authService)
        }
        .task {
            guard !authService.isGuestMode else { return }

            // Start crash detection monitoring
            crashService.startMonitoring {
                NotificationService.shared.sendFallDetectionAlert()
            }

            // Request notification permissions
            await NotificationService.shared.requestAuthorization()

            // Start location monitoring
            LocationService.shared.requestAuthorization()
            await LocationService.shared.loadAndMonitorZones()
        }
    }
}
