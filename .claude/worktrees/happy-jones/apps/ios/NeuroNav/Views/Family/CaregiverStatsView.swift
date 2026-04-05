import SwiftUI
import Charts
import NeuroNavKit

struct CaregiverStatsView: View {
    let link: CaregiverLinkRow
    @Bindable var vm: FamilyViewModel
    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { colorScheme == .dark }
    private var executions: [ExecutionRow] { vm.patientExecutions }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if executions.isEmpty {
                    ContentUnavailableView(
                        "Sin datos aún",
                        systemImage: "chart.bar.xaxis",
                        description: Text("Las estadísticas aparecerán cuando el paciente complete rutinas.")
                    )
                } else {
                    summaryCards
                    completionChart
                    errorsChart
                    weeklyActivityChart
                    complexitySection
                }
            }
            .padding(20)
        }
        .background(isDark ? Color.nnNightBG : Color(.systemGroupedBackground))
        .navigationTitle("Estadísticas")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        let completed = executions.filter { $0.status == "completed" }.count
        let total = executions.count
        let rate = total > 0 ? Double(completed) / Double(total) * 100 : 0
        let totalErrors = executions.reduce(0) { $0 + $1.errorCount }
        let totalStalls = executions.reduce(0) { $0 + $1.stallCount }

        return LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            statCard(title: "Completadas", value: "\(completed)/\(total)", icon: "checkmark.circle.fill", color: .nnSuccess)
            statCard(title: "Tasa de éxito", value: "\(Int(rate))%", icon: "chart.line.uptrend.xyaxis", color: .nnPrimary)
            statCard(title: "Errores totales", value: "\(totalErrors)", icon: "exclamationmark.triangle.fill", color: .nnError)
            statCard(title: "Bloqueos", value: "\(totalStalls)", icon: "pause.circle.fill", color: .nnWarning)
        }
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(color)
                Spacer()
            }
            HStack {
                Text(value)
                    .font(.nnTitle2)
                    .foregroundStyle(isDark ? .white : .nnDarkText)
                Spacer()
            }
            HStack {
                Text(title)
                    .font(.nnCaption)
                    .foregroundStyle(.nnMidGray)
                Spacer()
            }
        }
        .padding(14)
        .background(isDark ? Color.white.opacity(0.08) : .white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(isDark ? 0 : 0.04), radius: 4, y: 2)
    }

    // MARK: - Completion Chart

    private var completionChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rutinas completadas vs abandonadas")
                .font(.nnHeadline)
                .foregroundStyle(isDark ? .white : .nnDarkText)

            let completed = executions.filter { $0.status == "completed" }.count
            let abandoned = executions.filter { $0.status == "abandoned" }.count
            let inProgress = executions.filter { $0.status == "in_progress" }.count

            Chart {
                SectorMark(angle: .value("Completadas", completed), innerRadius: .ratio(0.6))
                    .foregroundStyle(Color.nnSuccess)
                    .annotation(position: .overlay) {
                        if completed > 0 {
                            Text("\(completed)")
                                .font(.nnCaption)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                    }

                SectorMark(angle: .value("Abandonadas", abandoned), innerRadius: .ratio(0.6))
                    .foregroundStyle(Color.nnError)
                    .annotation(position: .overlay) {
                        if abandoned > 0 {
                            Text("\(abandoned)")
                                .font(.nnCaption)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                    }

                if inProgress > 0 {
                    SectorMark(angle: .value("En progreso", inProgress), innerRadius: .ratio(0.6))
                        .foregroundStyle(Color.nnWarning)
                }
            }
            .frame(height: 200)

            HStack(spacing: 16) {
                legendItem(color: .nnSuccess, label: "Completadas")
                legendItem(color: .nnError, label: "Abandonadas")
                if executions.contains(where: { $0.status == "in_progress" }) {
                    legendItem(color: .nnWarning, label: "En progreso")
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(16)
        .background(isDark ? Color.white.opacity(0.08) : .white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(isDark ? 0 : 0.04), radius: 4, y: 2)
    }

    // MARK: - Errors Chart

    private var errorsChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Errores y bloqueos por sesión")
                .font(.nnHeadline)
                .foregroundStyle(isDark ? .white : .nnDarkText)

            let recentExecs = Array(executions.prefix(10).reversed())

            Chart {
                ForEach(Array(recentExecs.enumerated()), id: \.offset) { index, exec in
                    BarMark(
                        x: .value("Sesión", index + 1),
                        y: .value("Errores", exec.errorCount)
                    )
                    .foregroundStyle(Color.nnError.opacity(0.8))

                    BarMark(
                        x: .value("Sesión", index + 1),
                        y: .value("Bloqueos", exec.stallCount)
                    )
                    .foregroundStyle(Color.nnWarning.opacity(0.8))
                }
            }
            .chartXAxisLabel("Sesiones recientes")
            .chartYAxisLabel("Cantidad")
            .frame(height: 180)

            HStack(spacing: 16) {
                legendItem(color: .nnError, label: "Errores")
                legendItem(color: .nnWarning, label: "Bloqueos")
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(16)
        .background(isDark ? Color.white.opacity(0.08) : .white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(isDark ? 0 : 0.04), radius: 4, y: 2)
    }

    // MARK: - Weekly Activity

    private var weeklyActivityChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pasos completados por sesión")
                .font(.nnHeadline)
                .foregroundStyle(isDark ? .white : .nnDarkText)

            let recentExecs = Array(executions.prefix(10).reversed())

            Chart {
                ForEach(Array(recentExecs.enumerated()), id: \.offset) { index, exec in
                    LineMark(
                        x: .value("Sesión", index + 1),
                        y: .value("Pasos", exec.completedSteps)
                    )
                    .foregroundStyle(Color.nnPrimary)
                    .symbol(.circle)

                    AreaMark(
                        x: .value("Sesión", index + 1),
                        y: .value("Pasos", exec.completedSteps)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.nnPrimary.opacity(0.3), Color.nnPrimary.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
            .frame(height: 160)
        }
        .padding(16)
        .background(isDark ? Color.white.opacity(0.08) : .white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(isDark ? 0 : 0.04), radius: 4, y: 2)
    }

    // MARK: - Complexity

    private var complexitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nivel de complejidad")
                .font(.nnHeadline)
                .foregroundStyle(isDark ? .white : .nnDarkText)

            if let profile = vm.patientProfile {
                HStack(spacing: 0) {
                    ForEach(1...5, id: \.self) { level in
                        VStack(spacing: 6) {
                            Circle()
                                .fill(level == profile.currentComplexity ? Color.nnPrimary : (isDark ? Color.white.opacity(0.12) : Color.nnRule))
                                .frame(width: 36, height: 36)
                                .overlay {
                                    Text("\(level)")
                                        .font(.nnSubheadline)
                                        .fontWeight(.bold)
                                        .foregroundStyle(level == profile.currentComplexity ? .white : .nnMidGray)
                                }

                            if level == profile.currentComplexity {
                                Text("Actual")
                                    .font(.nnCaption2)
                                    .foregroundStyle(.nnPrimary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                HStack {
                    Text("Rango permitido: \(profile.complexityFloor) - \(profile.complexityCeiling)")
                        .font(.nnCaption)
                        .foregroundStyle(.nnMidGray)
                    Spacer()
                    Text("\(profile.totalSessions) sesiones totales")
                        .font(.nnCaption)
                        .foregroundStyle(.nnMidGray)
                }
            }
        }
        .padding(16)
        .background(isDark ? Color.white.opacity(0.08) : .white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(isDark ? 0 : 0.04), radius: 4, y: 2)
    }

    // MARK: - Helpers

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.nnCaption)
                .foregroundStyle(.nnMidGray)
        }
    }
}
