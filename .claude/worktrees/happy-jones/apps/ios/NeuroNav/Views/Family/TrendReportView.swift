import SwiftUI
import Charts
import NeuroNavKit

struct TrendReportView: View {
    let patientName: String
    let executions: [ExecutionRow]

    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { colorScheme == .dark }
    private var insights: [TrendInsight] {
        TrendAnalysisService.shared.analyze(executions: executions)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if executions.isEmpty {
                    ContentUnavailableView(
                        "Sin datos aun",
                        systemImage: "chart.line.text.clipboard",
                        description: Text("Los insights aparecerán cuando haya ejecuciones registradas.")
                    )
                } else {
                    summaryCard
                    completionRateChart
                    insightsList
                }
            }
            .padding(20)
        }
        .background(isDark ? Color.nnNightBG : Color(.systemGroupedBackground))
        .navigationTitle("Tendencias de \(patientName)")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        let now = Date()
        let cal = Calendar.current
        let thisWeek = datedExecutions.filter { cal.dateComponents([.day], from: $0.1, to: now).day ?? 99 < 7 }
        let lastWeek = datedExecutions.filter {
            let days = cal.dateComponents([.day], from: $0.1, to: now).day ?? 99
            return days >= 7 && days < 14
        }

        let thisCompleted = thisWeek.filter { $0.0.status == "completed" }.count
        let lastCompleted = lastWeek.filter { $0.0.status == "completed" }.count
        let thisTotal = thisWeek.count
        let lastTotal = lastWeek.count
        let thisRate = thisTotal > 0 ? Int(Double(thisCompleted) / Double(thisTotal) * 100) : 0
        let lastRate = lastTotal > 0 ? Int(Double(lastCompleted) / Double(lastTotal) * 100) : 0
        let rateDelta = thisRate - lastRate

        return VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Esta semana")
                        .font(.nnCaption)
                        .foregroundStyle(.nnMidGray)
                    Text("\(thisRate)% exito")
                        .font(.nnTitle2)
                        .foregroundStyle(isDark ? .white : .nnDarkText)
                    Text("\(thisCompleted)/\(thisTotal) completadas")
                        .font(.nnCaption)
                        .foregroundStyle(.nnMidGray)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("vs semana pasada")
                        .font(.nnCaption)
                        .foregroundStyle(.nnMidGray)

                    HStack(spacing: 4) {
                        Image(systemName: rateDelta >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 12, weight: .bold))
                        Text("\(abs(rateDelta))%")
                            .font(.nnHeadline)
                    }
                    .foregroundStyle(rateDelta >= 0 ? Color.nnSuccess : Color.nnError)

                    Text("\(lastCompleted)/\(lastTotal) completadas")
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

    // MARK: - Completion Rate Chart (30 days)

    private var completionRateChart: some View {
        let dailyRates = computeDailyRates()

        return VStack(alignment: .leading, spacing: 12) {
            Text("Tasa de completado diaria")
                .font(.nnHeadline)
                .foregroundStyle(isDark ? .white : .nnDarkText)

            if dailyRates.isEmpty {
                Text("Datos insuficientes para graficar.")
                    .font(.nnCaption)
                    .foregroundStyle(.nnMidGray)
            } else {
                Chart {
                    ForEach(dailyRates, id: \.date) { point in
                        LineMark(
                            x: .value("Dia", point.date, unit: .day),
                            y: .value("Tasa", point.rate)
                        )
                        .foregroundStyle(Color.nnPrimary)
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Dia", point.date, unit: .day),
                            y: .value("Tasa", point.rate)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.nnPrimary.opacity(0.3), Color.nnPrimary.opacity(0.02)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartYScale(domain: 0...100)
                .chartYAxisLabel("% exito")
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated), centered: true)
                    }
                }
                .frame(height: 180)
            }
        }
        .padding(16)
        .background(isDark ? Color.white.opacity(0.08) : .white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(isDark ? 0 : 0.04), radius: 4, y: 2)
    }

    // MARK: - Insights List

    private var insightsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights")
                .font(.nnHeadline)
                .foregroundStyle(isDark ? .white : .nnDarkText)

            if insights.isEmpty {
                Text("No hay insights con los datos actuales. Se necesitan mas ejecuciones.")
                    .font(.nnBody)
                    .foregroundStyle(.nnMidGray)
                    .padding(.vertical, 8)
            } else {
                ForEach(insights) { insight in
                    insightCard(insight)
                }
            }
        }
    }

    private func insightCard(_ insight: TrendInsight) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: insight.icon)
                .font(.system(size: 22))
                .foregroundStyle(insight.color)
                .frame(width: 36, height: 36)
                .background(insight.color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.nnHeadline)
                    .foregroundStyle(isDark ? .white : .nnDarkText)
                Text(insight.description)
                    .font(.nnBody)
                    .foregroundStyle(.nnMidGray)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(isDark ? Color.white.opacity(0.08) : .white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(isDark ? 0 : 0.04), radius: 4, y: 2)
    }

    // MARK: - Helpers

    private struct DailyRate {
        let date: Date
        let rate: Double
    }

    private var datedExecutions: [(ExecutionRow, Date)] {
        let isoFull = ISO8601DateFormatter()
        isoFull.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoBasic = ISO8601DateFormatter()
        isoBasic.formatOptions = [.withInternetDateTime]

        return executions.compactMap { exec in
            let date = isoFull.date(from: exec.startedAt) ?? isoBasic.date(from: exec.startedAt)
            guard let d = date else { return nil }
            return (exec, d)
        }
    }

    private func computeDailyRates() -> [DailyRate] {
        let cal = Calendar.current
        let now = Date()
        guard let thirtyDaysAgo = cal.date(byAdding: .day, value: -30, to: now) else { return [] }

        let recent = datedExecutions.filter { $0.1 >= thirtyDaysAgo }
        guard !recent.isEmpty else { return [] }

        let grouped = Dictionary(grouping: recent) { cal.startOfDay(for: $0.1) }

        return grouped.map { (day, items) in
            let completed = items.filter { $0.0.status == "completed" }.count
            let rate = Double(completed) / Double(items.count) * 100
            return DailyRate(date: day, rate: rate)
        }
        .sorted { $0.date < $1.date }
    }
}

