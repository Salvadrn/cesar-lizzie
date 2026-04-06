import SwiftUI
import SwiftData
import NeuroNavKit

struct GamificationView: View {
    @Environment(AdaptiveEngine.self) private var engine
    @Environment(AuthService.self) private var authService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @State private var vm = GamificationViewModel()

    private var level: Int { engine.currentLevel }
    private var isDark: Bool { colorScheme == .dark }

    private var userId: String {
        authService.userId?.uuidString ?? "guest"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Level & points card
                levelCard

                // Streak card
                streakCard

                // Achievements
                achievementsSection
            }
            .padding(16)
        }
        .background(isDark ? Color.nnNightBG : Color(.systemGroupedBackground))
        .navigationTitle(level <= 2 ? "Logros" : "Mis Logros")
        .navigationBarTitleDisplayMode(level <= 2 ? .inline : .large)
        .onAppear {
            vm.loadStats(context: modelContext, userId: userId)
        }
        .overlay {
            if vm.showUnlockAnimation, let achievement = vm.lastUnlockedAchievement {
                AchievementUnlockOverlay(achievement: achievement, level: level) {
                    vm.showUnlockAnimation = false
                }
            }
        }
    }

    // MARK: - Level Card

    private var levelCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                Image(systemName: vm.levelIcon)
                    .font(.system(size: level <= 2 ? 48 : 40))
                    .foregroundStyle(.nnWarning)
                    .symbolEffect(.pulse)

                VStack(alignment: .leading, spacing: 4) {
                    Text(vm.levelName)
                        .font(level <= 2 ? .title.bold() : .title2.bold())

                    Text("\(vm.stats?.totalPoints ?? 0) puntos")
                        .font(level <= 2 ? .title3 : .subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            // Progress to next level
            VStack(alignment: .leading, spacing: 6) {
                ProgressView(value: vm.levelProgress)
                    .tint(.nnPrimary)

                if level >= 3 {
                    Text("Faltan \(vm.nextLevelPoints - (vm.stats?.totalPoints ?? 0)) puntos para el siguiente nivel")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Stats grid
            if level >= 2 {
                HStack(spacing: 0) {
                    statItem(
                        icon: "list.clipboard.fill",
                        value: "\(vm.stats?.routinesCompleted ?? 0)",
                        label: "Rutinas"
                    )
                    Divider().frame(height: 40)
                    statItem(
                        icon: "pill.fill",
                        value: "\(vm.stats?.medicationsTaken ?? 0)",
                        label: "Medicinas"
                    )
                    Divider().frame(height: 40)
                    statItem(
                        icon: "face.smiling",
                        value: "\(vm.stats?.moodEntriesLogged ?? 0)",
                        label: "Check-ins"
                    )
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [
                    isDark ? Color(.systemGray6) : .white,
                    isDark ? Color(.systemGray6) : Color.nnTint.opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func statItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.nnPrimary)
            Text(value)
                .font(.headline.monospacedDigit())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "flame.fill")
                .font(.system(size: level <= 2 ? 44 : 36))
                .foregroundStyle(
                    (vm.stats?.currentStreak ?? 0) > 0 ? .orange : .nnMidGray
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(level <= 2 ? "Racha" : "Racha actual")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(vm.stats?.currentStreak ?? 0)")
                        .font(.system(size: level <= 2 ? 36 : 28, weight: .bold, design: .rounded))
                    Text(level <= 2 ? "días" : "días seguidos")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if level >= 3 {
                VStack(spacing: 2) {
                    Text("Récord")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(vm.stats?.longestStreak ?? 0)")
                        .font(.title3.bold())
                        .foregroundStyle(.nnPrimary)
                }
            }
        }
        .padding(20)
        .background(isDark ? Color(.systemGray6) : .white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Achievements Section

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(level <= 2 ? "Logros" : "Logros y medallas")
                .font(.headline)

            let unlocked = vm.achievements.filter { $0.isUnlocked }
            let locked = vm.achievements.filter { !$0.isUnlocked }

            if !unlocked.isEmpty {
                ForEach(unlocked) { achievement in
                    achievementRow(achievement, unlocked: true)
                }
            }

            if !locked.isEmpty {
                if level >= 3 {
                    Text("Por desbloquear")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                }

                ForEach(locked) { achievement in
                    achievementRow(achievement, unlocked: false)
                }
            }
        }
        .padding(20)
        .background(isDark ? Color(.systemGray6) : .white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func achievementRow(_ achievement: NNAchievement, unlocked: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: achievement.icon)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(unlocked ? Color.nnPrimary.opacity(0.15) : Color(.systemGray5))
                .foregroundStyle(unlocked ? .nnPrimary : .nnMidGray)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(unlocked ? .primary : .secondary)

                if level >= 2 {
                    Text(achievement.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if unlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.nnSuccess)
            }
        }
        .padding(12)
        .background(isDark ? Color(.systemGray5) : Color(.systemGray6).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .opacity(unlocked ? 1 : 0.7)
    }
}

// MARK: - Achievement Unlock Overlay

struct AchievementUnlockOverlay: View {
    let achievement: NNAchievement
    let level: Int
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 20) {
                Image(systemName: achievement.icon)
                    .font(.system(size: 64))
                    .foregroundStyle(.nnWarning)
                    .symbolEffect(.bounce)

                Text(level <= 2 ? "Nuevo logro!" : "Logro desbloqueado!")
                    .font(.title2.bold())

                Text(achievement.title)
                    .font(.title3)
                    .foregroundStyle(.secondary)

                Button {
                    onDismiss()
                } label: {
                    Text("Genial!")
                        .font(.headline)
                        .frame(width: 160)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.nnPrimary)
            }
            .padding(32)
            .background(.ultraThickMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1
            }
        }
    }
}
