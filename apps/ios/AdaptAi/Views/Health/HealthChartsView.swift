import SwiftUI
import Charts
import AdaptAiKit

/// Graficas de los ultimos 7 dias con datos de HealthKit.
/// Usa el framework Charts nativo de iOS 16+.
/// Componente inline — se embebe en HealthView sin navegacion propia.
struct HealthChartsView: View {
    @State private var health = HealthKitService.shared
    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Ultimos 7 dias")
                    .font(.nnHeadline)
                    .foregroundStyle(isDark ? .white : .nnDarkText)
                Spacer()
            }

            stepsChart
            heartRateChart
            sleepChart
            caloriesChart
        }
    }

    // MARK: - Steps

    private var stepsChart: some View {
        chartCard(
            title: "Pasos",
            subtitle: avgSubtitle(health.stepsLast7Days, unit: "pasos/dia"),
            icon: "figure.walk",
            color: .nnPrimary
        ) {
            if health.stepsLast7Days.isEmpty {
                emptyChart
            } else {
                Chart(health.stepsLast7Days) { point in
                    BarMark(
                        x: .value("Dia", point.date, unit: .day),
                        y: .value("Pasos", point.value)
                    )
                    .foregroundStyle(Color.nnPrimary.gradient)
                    .cornerRadius(6)
                }
                .frame(height: 160)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated), centered: true)
                    }
                }
            }
        }
    }

    // MARK: - Heart Rate

    private var heartRateChart: some View {
        chartCard(
            title: "Ritmo cardiaco",
            subtitle: avgSubtitle(health.heartRateLast7Days, unit: "BPM promedio"),
            icon: "heart.fill",
            color: .red
        ) {
            if health.heartRateLast7Days.isEmpty {
                emptyChart
            } else {
                Chart(health.heartRateLast7Days) { point in
                    LineMark(
                        x: .value("Dia", point.date, unit: .day),
                        y: .value("BPM", point.value)
                    )
                    .foregroundStyle(Color.red.gradient)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 3))

                    PointMark(
                        x: .value("Dia", point.date, unit: .day),
                        y: .value("BPM", point.value)
                    )
                    .foregroundStyle(Color.red)
                    .symbolSize(50)
                }
                .frame(height: 160)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated), centered: true)
                    }
                }
            }
        }
    }

    // MARK: - Sleep

    private var sleepChart: some View {
        chartCard(
            title: "Sueño",
            subtitle: avgSubtitle(health.sleepLast7Days, unit: "horas/noche", formatter: { String(format: "%.1f", $0) }),
            icon: "bed.double.fill",
            color: .indigo
        ) {
            if health.sleepLast7Days.isEmpty {
                emptyChart
            } else {
                Chart(health.sleepLast7Days) { point in
                    BarMark(
                        x: .value("Dia", point.date, unit: .day),
                        y: .value("Horas", point.value)
                    )
                    .foregroundStyle(sleepQualityColor(hours: point.value).gradient)
                    .cornerRadius(6)

                    RuleMark(y: .value("Recomendado", 8))
                        .foregroundStyle(Color.nnSuccess.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("8h")
                                .font(.nnCaption2)
                                .foregroundStyle(.nnSuccess)
                        }
                }
                .frame(height: 160)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated), centered: true)
                    }
                }
            }
        }
    }

    // MARK: - Calories

    private var caloriesChart: some View {
        chartCard(
            title: "Calorias activas",
            subtitle: avgSubtitle(health.caloriesLast7Days, unit: "kcal/dia"),
            icon: "flame.fill",
            color: .orange
        ) {
            if health.caloriesLast7Days.isEmpty {
                emptyChart
            } else {
                Chart(health.caloriesLast7Days) { point in
                    AreaMark(
                        x: .value("Dia", point.date, unit: .day),
                        y: .value("kcal", point.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.6), Color.orange.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Dia", point.date, unit: .day),
                        y: .value("kcal", point.value)
                    )
                    .foregroundStyle(Color.orange)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                }
                .frame(height: 160)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated), centered: true)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func chartCard<Content: View>(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(color)
                    .frame(width: 36, height: 36)
                    .background(color.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.nnHeadline)
                        .foregroundStyle(isDark ? .white : .nnDarkText)
                    Text(subtitle)
                        .font(.nnCaption)
                        .foregroundStyle(.nnMidGray)
                }
                Spacer()
            }

            content()
        }
        .padding(16)
        .background(isDark ? Color.white.opacity(0.06) : Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var emptyChart: some View {
        HStack(spacing: 8) {
            Image(systemName: "chart.line.downtrend.xyaxis")
                .foregroundStyle(.nnMidGray)
            Text("Sin datos en los ultimos 7 dias")
                .font(.nnCaption)
                .foregroundStyle(.nnMidGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private func avgSubtitle(
        _ data: [HealthDataPoint],
        unit: String,
        formatter: ((Double) -> String)? = nil
    ) -> String {
        guard !data.isEmpty else { return "Sin datos" }
        let avg = data.map { $0.value }.reduce(0, +) / Double(data.count)
        let formatted = formatter?(avg) ?? formatNumber(Int(avg))
        return "\(formatted) \(unit)"
    }

    private func sleepQualityColor(hours: Double) -> Color {
        switch hours {
        case 7...: return .nnSuccess
        case 5..<7: return .nnWarning
        default: return .nnError
        }
    }

    private func formatNumber(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}
