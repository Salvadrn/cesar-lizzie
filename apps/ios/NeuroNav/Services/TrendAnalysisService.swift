import Foundation
import SwiftUI
import NeuroNavKit

// MARK: - TrendInsight Model

struct TrendInsight: Identifiable {
    let id = UUID()
    let type: InsightType
    let title: String
    let description: String
    let icon: String
    let color: Color
    let priority: Int // 1=high, 3=low

    enum InsightType {
        case improvement, warning, pattern, milestone
    }
}

// MARK: - TrendAnalysisService

@Observable
final class TrendAnalysisService {
    static let shared = TrendAnalysisService()

    private let calendar = Calendar.current
    private let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private let isoFormatterFallback: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    init() {}

    // MARK: - Public API

    func analyze(executions: [ExecutionRow]) -> [TrendInsight] {
        guard !executions.isEmpty else { return [] }

        var insights: [TrendInsight] = []

        let dated = executions.compactMap { exec -> (ExecutionRow, Date)? in
            guard let date = parseDate(exec.startedAt) else { return nil }
            return (exec, date)
        }.sorted { $0.1 < $1.1 }

        let now = Date()

        // 1. Improvement / Regression
        if let improvementInsight = analyzeSuccessRateTrend(dated: dated, now: now) {
            insights.append(improvementInsight)
        }

        // 2. Error rate change
        if let errorInsight = analyzeErrorTrend(dated: dated, now: now) {
            insights.append(errorInsight)
        }

        // 3 & 4. Time-of-day patterns
        insights.append(contentsOf: analyzeTimeOfDayPatterns(dated: dated))

        // 5. Stall concentration by routine
        insights.append(contentsOf: analyzeStallConcentration(dated: dated))

        // 6. Streak milestone
        if let streakInsight = analyzeStreak(dated: dated, now: now) {
            insights.append(streakInsight)
        }

        // 7. Complexity change recommendation
        if let complexityInsight = analyzeComplexityRecommendation(dated: dated, now: now) {
            insights.append(complexityInsight)
        }

        // 8. Weekly summary
        if let summaryInsight = buildWeeklySummary(dated: dated, now: now) {
            insights.append(summaryInsight)
        }

        return insights.sorted { $0.priority < $1.priority }
    }

    // MARK: - 1. Success Rate Trend

    private func analyzeSuccessRateTrend(dated: [(ExecutionRow, Date)], now: Date) -> TrendInsight? {
        let thisWeek = dated.filter { calendar.dateComponents([.day], from: $0.1, to: now).day ?? 99 < 7 }
        let lastWeek = dated.filter {
            let days = calendar.dateComponents([.day], from: $0.1, to: now).day ?? 99
            return days >= 7 && days < 14
        }

        guard thisWeek.count >= 2, lastWeek.count >= 2 else { return nil }

        let thisRate = successRate(thisWeek.map { $0.0 })
        let lastRate = successRate(lastWeek.map { $0.0 })

        if thisRate > lastRate + 10 {
            return TrendInsight(
                type: .improvement,
                title: "Mejorando",
                description: "La tasa de exito subio de \(Int(lastRate))% a \(Int(thisRate))% esta semana.",
                icon: "arrow.up.right.circle.fill",
                color: .nnSuccess,
                priority: 1
            )
        } else if thisRate < lastRate - 10 {
            return TrendInsight(
                type: .warning,
                title: "Regresion detectada",
                description: "La tasa de exito bajo de \(Int(lastRate))% a \(Int(thisRate))% esta semana.",
                icon: "arrow.down.right.circle.fill",
                color: .nnError,
                priority: 1
            )
        }
        return nil
    }

    // MARK: - 2. Error Trend

    private func analyzeErrorTrend(dated: [(ExecutionRow, Date)], now: Date) -> TrendInsight? {
        let thisWeek = dated.filter { calendar.dateComponents([.day], from: $0.1, to: now).day ?? 99 < 7 }
        let lastWeek = dated.filter {
            let days = calendar.dateComponents([.day], from: $0.1, to: now).day ?? 99
            return days >= 7 && days < 14
        }

        guard thisWeek.count >= 2, lastWeek.count >= 2 else { return nil }

        let thisErrors = Double(thisWeek.map { $0.0.errorCount }.reduce(0, +)) / Double(thisWeek.count)
        let lastErrors = Double(lastWeek.map { $0.0.errorCount }.reduce(0, +)) / Double(lastWeek.count)

        if thisErrors > lastErrors * 1.5 && thisErrors > 1 {
            return TrendInsight(
                type: .warning,
                title: "Atencion",
                description: "Los errores aumentaron esta semana (promedio \(String(format: "%.1f", thisErrors)) vs \(String(format: "%.1f", lastErrors))).",
                icon: "exclamationmark.triangle.fill",
                color: .nnError,
                priority: 1
            )
        }
        return nil
    }

    // MARK: - 3 & 4. Time-of-Day Patterns

    private func analyzeTimeOfDayPatterns(dated: [(ExecutionRow, Date)]) -> [TrendInsight] {
        guard dated.count >= 5 else { return [] }

        struct TimeBucket {
            let label: String
            var executions: [ExecutionRow] = []
        }

        var morning = TimeBucket(label: "manana")    // 6-12
        var afternoon = TimeBucket(label: "tarde")    // 12-18
        var evening = TimeBucket(label: "noche")      // 18-24
        var night = TimeBucket(label: "madrugada")    // 0-6

        for (exec, date) in dated {
            let hour = calendar.component(.hour, from: date)
            switch hour {
            case 6..<12: morning.executions.append(exec)
            case 12..<18: afternoon.executions.append(exec)
            case 18..<24: evening.executions.append(exec)
            default: night.executions.append(exec)
            }
        }

        let buckets = [morning, afternoon, evening, night].filter { $0.executions.count >= 2 }
        guard buckets.count >= 2 else { return [] }

        var insights: [TrendInsight] = []

        let rates = buckets.map { (bucket: $0, rate: successRate($0.executions), errors: avgErrors($0.executions)) }
        if let best = rates.max(by: { $0.rate < $1.rate }), best.rate > 70 {
            insights.append(TrendInsight(
                type: .pattern,
                title: "Mejor rendimiento",
                description: "Las rutinas de la \(best.bucket.label) tienen menos errores (\(Int(best.rate))% exito).",
                icon: "sun.max.fill",
                color: .nnPrimary,
                priority: 2
            ))
        }

        if let worst = rates.min(by: { $0.rate < $1.rate }), worst.rate < 60 {
            let hour = worst.bucket.label == "tarde" ? "3pm" : (worst.bucket.label == "noche" ? "6pm" : "mediodia")
            insights.append(TrendInsight(
                type: .warning,
                title: "Dificultad por la \(worst.bucket.label)",
                description: "Mas bloqueos despues de las \(hour) (\(Int(worst.rate))% exito).",
                icon: "moon.fill",
                color: .nnWarning,
                priority: 2
            ))
        }

        return insights
    }

    // MARK: - 5. Stall Concentration

    private func analyzeStallConcentration(dated: [(ExecutionRow, Date)]) -> [TrendInsight] {
        guard dated.count >= 3 else { return [] }

        let byRoutine = Dictionary(grouping: dated.map { $0.0 }, by: \.routineId)
        let globalAvgStalls = Double(dated.map { $0.0.stallCount }.reduce(0, +)) / Double(dated.count)

        var insights: [TrendInsight] = []
        for (routineId, execs) in byRoutine where execs.count >= 2 {
            let routineAvgStalls = Double(execs.map { $0.stallCount }.reduce(0, +)) / Double(execs.count)
            if routineAvgStalls > globalAvgStalls * 1.5 && routineAvgStalls > 1 {
                let shortId = String(routineId.prefix(8))
                insights.append(TrendInsight(
                    type: .warning,
                    title: "Rutina dificil",
                    description: "La rutina \(shortId)... tiene mas bloqueos que el promedio (\(String(format: "%.1f", routineAvgStalls)) vs \(String(format: "%.1f", globalAvgStalls))).",
                    icon: "tortoise.fill",
                    color: .nnWarning,
                    priority: 2
                ))
            }
        }
        return insights
    }

    // MARK: - 6. Streak

    private func analyzeStreak(dated: [(ExecutionRow, Date)], now: Date) -> TrendInsight? {
        let completedDates = Set(
            dated
                .filter { $0.0.status == "completed" }
                .map { calendar.startOfDay(for: $0.1) }
        )

        guard !completedDates.isEmpty else { return nil }

        var streak = 0
        var checkDate = calendar.startOfDay(for: now)

        while completedDates.contains(checkDate) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previous
        }

        guard streak >= 3 else { return nil }

        return TrendInsight(
            type: .milestone,
            title: "Racha de \(streak) dias",
            description: "Lleva \(streak) dias consecutivos completando rutinas.",
            icon: "flame.fill",
            color: .nnPrimary,
            priority: 1
        )
    }

    // MARK: - 7. Complexity Recommendation

    private func analyzeComplexityRecommendation(dated: [(ExecutionRow, Date)], now: Date) -> TrendInsight? {
        let twoWeeks = dated.filter {
            (calendar.dateComponents([.day], from: $0.1, to: now).day ?? 99) < 14
        }

        guard twoWeeks.count >= 5 else { return nil }

        let rate = successRate(twoWeeks.map { $0.0 })
        if rate > 90 {
            return TrendInsight(
                type: .improvement,
                title: "Considerar subir nivel",
                description: "Tasa de exito de \(Int(rate))% en 2 semanas. Podria beneficiarse de mayor complejidad.",
                icon: "arrow.up.circle.fill",
                color: .nnPrimary,
                priority: 2
            )
        }
        return nil
    }

    // MARK: - 8. Weekly Summary

    private func buildWeeklySummary(dated: [(ExecutionRow, Date)], now: Date) -> TrendInsight? {
        let thisWeek = dated.filter { calendar.dateComponents([.day], from: $0.1, to: now).day ?? 99 < 7 }
        guard !thisWeek.isEmpty else { return nil }

        let completed = thisWeek.filter { $0.0.status == "completed" }.count
        let errors = thisWeek.map { $0.0.errorCount }.reduce(0, +)
        let totalSteps = thisWeek.map { $0.0.completedSteps }.reduce(0, +)

        return TrendInsight(
            type: .pattern,
            title: "Resumen semanal",
            description: "\(completed) completadas, \(errors) errores, \(totalSteps) pasos esta semana.",
            icon: "calendar.badge.checkmark",
            color: .nnPrimary,
            priority: 3
        )
    }

    // MARK: - Helpers

    private func parseDate(_ iso: String) -> Date? {
        if let d = isoFormatter.date(from: iso) { return d }
        return isoFormatterFallback.date(from: iso)
    }

    private func successRate(_ executions: [ExecutionRow]) -> Double {
        guard !executions.isEmpty else { return 0 }
        let completed = executions.filter { $0.status == "completed" }.count
        return Double(completed) / Double(executions.count) * 100
    }

    private func avgErrors(_ executions: [ExecutionRow]) -> Double {
        guard !executions.isEmpty else { return 0 }
        return Double(executions.map { $0.errorCount }.reduce(0, +)) / Double(executions.count)
    }
}
