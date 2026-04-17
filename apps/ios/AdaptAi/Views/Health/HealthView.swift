import SwiftUI
import AdaptAiKit

struct HealthView: View {
    @Environment(AdaptiveEngine.self) private var engine
    @Environment(AuthService.self) private var authService
    @Environment(\.colorScheme) private var colorScheme
    @State private var health = HealthKitService.shared
    @State private var hasRequestedAuth = false

    private var isDark: Bool { colorScheme == .dark }
    private var level: Int { engine.currentLevel }

    var body: some View {
        Group {
            if !health.isAvailable {
                ContentUnavailableView(
                    "Salud no disponible",
                    systemImage: "heart.slash",
                    description: Text("Este dispositivo no soporta HealthKit")
                )
            } else if !health.isAuthorized && !hasRequestedAuth {
                connectHealthView
            } else {
                healthDashboard
            }
        }
        .navigationTitle("Salud")
        .task {
            if health.isAuthorized {
                await health.fetchAll()
            }
        }
        .refreshable {
            await health.fetchAll()
        }
    }

    // MARK: - Connect View

    private var connectHealthView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "heart.text.clipboard")
                .font(.system(size: 64))
                .foregroundStyle(.nnPrimary)

            Text("Conecta tu salud")
                .font(.nnTitle)
                .foregroundStyle(isDark ? .white : .nnDarkText)

            Text("Accede a tus datos de salud del Apple Watch y el iPhone para un mejor seguimiento.")
                .font(.nnSubheadline)
                .foregroundStyle(.nnMidGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                Task {
                    hasRequestedAuth = true
                    let authorized = await health.requestAuthorization()
                    if authorized {
                        await health.fetchAll()
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                    Text("Conectar HealthKit")
                }
                .font(.nnHeadline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.nnPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .background(isDark ? Color.nnNightBG : Color(.systemGroupedBackground))
    }

    // MARK: - Dashboard

    private var healthDashboard: some View {
        ScrollView {
            VStack(spacing: level <= 2 ? 20 : 16) {
                // Vitals
                if level <= 2 {
                    simpleVitals
                } else {
                    detailedVitals
                }

                // Activity
                activitySection

                // Sleep
                if let sleep = health.sleepHoursLastNight {
                    sleepCard(hours: sleep)
                }

                // Body
                if level >= 3 {
                    bodySection
                }

                // Charts link (level 2+)
                if level >= 2 {
                    NavigationLink {
                        HealthChartsView()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "chart.xyaxis.line")
                                .font(.system(size: 20))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.nnPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Ver graficas")
                                    .font(.nnHeadline)
                                    .foregroundStyle(isDark ? .white : .nnDarkText)
                                Text("Tendencias de los ultimos 7 dias")
                                    .font(.nnCaption)
                                    .foregroundStyle(.nnMidGray)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.nnMidGray)
                        }
                        .padding(14)
                        .background(isDark ? Color.white.opacity(0.08) : Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
            .padding(20)
        }
        .background(isDark ? Color.nnNightBG : Color(.systemGroupedBackground))
    }

    // MARK: - Simple Vitals (Level 1-2)

    private var simpleVitals: some View {
        VStack(spacing: 12) {
            if let hr = health.heartRate {
                bigVitalCard(
                    title: "Ritmo cardíaco",
                    value: "\(Int(hr))",
                    unit: "BPM",
                    icon: "heart.fill",
                    color: .red
                )
            }

            HStack(spacing: 12) {
                if health.stepsToday > 0 {
                    smallVitalCard(
                        title: "Pasos",
                        value: formatNumber(health.stepsToday),
                        icon: "figure.walk",
                        color: .nnPrimary
                    )
                }

                if let o2 = health.bloodOxygen {
                    smallVitalCard(
                        title: "Oxígeno",
                        value: "\(Int(o2))%",
                        icon: "lungs.fill",
                        color: .cyan
                    )
                }
            }
        }
    }

    // MARK: - Detailed Vitals (Level 3+)

    private var detailedVitals: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Signos vitales")
                .font(.nnHeadline)
                .foregroundStyle(isDark ? .white : .nnDarkText)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                if let hr = health.heartRate {
                    vitalTile(title: "Ritmo cardíaco", value: "\(Int(hr))", unit: "BPM", icon: "heart.fill", color: .red)
                }

                if let rhr = health.restingHeartRate {
                    vitalTile(title: "En reposo", value: "\(Int(rhr))", unit: "BPM", icon: "heart.circle", color: .pink)
                }

                if let o2 = health.bloodOxygen {
                    vitalTile(title: "Oxígeno", value: "\(Int(o2))", unit: "%", icon: "lungs.fill", color: .cyan)
                }

                if let sys = health.bloodPressureSystolic, let dia = health.bloodPressureDiastolic {
                    vitalTile(title: "Presión", value: "\(Int(sys))/\(Int(dia))", unit: "mmHg", icon: "waveform.path.ecg", color: .purple)
                }
            }

            if health.heartRate == nil && health.bloodOxygen == nil {
                HStack(spacing: 8) {
                    Image(systemName: "applewatch")
                        .foregroundStyle(.nnMidGray)
                    Text("Conecta tu Apple Watch para ver signos vitales")
                        .font(.nnCaption)
                        .foregroundStyle(.nnMidGray)
                }
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(isDark ? Color.white.opacity(0.06) : Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Activity

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if level >= 3 {
                Text("Actividad de hoy")
                    .font(.nnHeadline)
                    .foregroundStyle(isDark ? .white : .nnDarkText)
            }

            HStack(spacing: 12) {
                activityTile(
                    title: "Pasos",
                    value: formatNumber(health.stepsToday),
                    icon: "figure.walk",
                    color: .nnPrimary
                )

                activityTile(
                    title: "Calorías",
                    value: "\(Int(health.activeCaloriesToday))",
                    icon: "flame.fill",
                    color: .orange
                )

                activityTile(
                    title: "Ejercicio",
                    value: "\(Int(health.exerciseMinutesToday)) min",
                    icon: "figure.run",
                    color: .nnSuccess
                )
            }

            if level >= 4 && health.distanceToday > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "map")
                        .foregroundStyle(.nnPrimary)
                    Text("Distancia: \(String(format: "%.1f", health.distanceToday / 1000)) km")
                        .font(.nnSubheadline)
                        .foregroundStyle(isDark ? .white : .nnDarkText)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(isDark ? Color.white.opacity(0.06) : Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Sleep

    private func sleepCard(hours: Double) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "bed.double.fill")
                .font(.system(size: level <= 2 ? 28 : 22))
                .foregroundStyle(.indigo)
                .frame(width: level <= 2 ? 52 : 40)

            VStack(alignment: .leading, spacing: 2) {
                Text("Sueño anoche")
                    .font(level <= 2 ? .nnHeadline : .nnSubheadline)
                    .foregroundStyle(isDark ? .white : .nnDarkText)
                Text("\(Int(hours))h \(Int((hours.truncatingRemainder(dividingBy: 1)) * 60))m")
                    .font(level <= 2 ? .nnTitle2 : .nnHeadline)
                    .foregroundStyle(.indigo)
            }

            Spacer()

            if level >= 3 {
                sleepQualityBadge(hours: hours)
            }
        }
        .padding(level <= 2 ? 18 : 14)
        .background(isDark ? Color.white.opacity(0.08) : Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: level <= 2 ? 18 : 14))
    }

    private func sleepQualityBadge(hours: Double) -> some View {
        let (text, color): (String, Color) = {
            switch hours {
            case 7...: return ("Bien", .nnSuccess)
            case 5..<7: return ("Regular", .nnWarning)
            default: return ("Bajo", .nnError)
            }
        }()

        return Text(text)
            .font(.nnCaption)
            .fontWeight(.bold)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    // MARK: - Body

    private var bodySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cuerpo")
                .font(.nnHeadline)
                .foregroundStyle(isDark ? .white : .nnDarkText)

            HStack(spacing: 12) {
                if let w = health.weight {
                    bodyTile(title: "Peso", value: String(format: "%.1f", w), unit: "kg", icon: "scalemass.fill")
                }
                if let h = health.height {
                    bodyTile(title: "Altura", value: String(format: "%.0f", h), unit: "cm", icon: "ruler.fill")
                }
                if let bmi = health.bmi {
                    bodyTile(title: "IMC", value: String(format: "%.1f", bmi), unit: "", icon: "chart.bar.fill")
                }
            }
        }
    }

    // MARK: - Components

    private func bigVitalCard(title: String, value: String, unit: String, icon: String, color: Color) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundStyle(color)
                .frame(width: 60)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.nnSubheadline)
                    .foregroundStyle(.nnMidGray)
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.nnLargeTitle)
                        .foregroundStyle(isDark ? .white : .nnDarkText)
                    Text(unit)
                        .font(.nnSubheadline)
                        .foregroundStyle(.nnMidGray)
                }
            }

            Spacer()
        }
        .padding(18)
        .background(isDark ? Color.white.opacity(0.08) : Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func smallVitalCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)
            Text(value)
                .font(.nnTitle2)
                .foregroundStyle(isDark ? .white : .nnDarkText)
            Text(title)
                .font(.nnCaption)
                .foregroundStyle(.nnMidGray)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(isDark ? Color.white.opacity(0.08) : Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func vitalTile(title: String, value: String, unit: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(color)
                Text(title)
                    .font(.nnCaption)
                    .foregroundStyle(.nnMidGray)
            }

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.nnTitle2)
                    .foregroundStyle(isDark ? .white : .nnDarkText)
                Text(unit)
                    .font(.nnCaption)
                    .foregroundStyle(.nnMidGray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(isDark ? Color.white.opacity(0.08) : Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func activityTile(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: level <= 2 ? 22 : 18))
                .foregroundStyle(color)
            Text(value)
                .font(level <= 2 ? .nnHeadline : .nnSubheadline)
                .foregroundStyle(isDark ? .white : .nnDarkText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.nnCaption2)
                .foregroundStyle(.nnMidGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(isDark ? Color.white.opacity(0.08) : Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func bodyTile(title: String, value: String, unit: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.nnPrimary)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.nnHeadline)
                    .foregroundStyle(isDark ? .white : .nnDarkText)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.nnCaption2)
                        .foregroundStyle(.nnMidGray)
                }
            }
            Text(title)
                .font(.nnCaption2)
                .foregroundStyle(.nnMidGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(isDark ? Color.white.opacity(0.06) : Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func formatNumber(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}
