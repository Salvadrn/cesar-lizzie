import Foundation
import SwiftUI
import AdaptAiKit

// MARK: - Lifestyle inputs

/// Lifestyle answers we can't pull from HealthKit. User fills them once,
/// can revise whenever. Persisted in UserDefaults.
/// Only available at complexity level 5 (most functional users).
struct BioAgeInputs: Codable, Equatable {
    var smokes: Bool = false
    var alcohol: AlcoholLevel = .light
    var stress: StressLevel = .medium
    var chronologicalAge: Int = 30
    var vo2Max: Double? = nil
    var heightCm: Double? = nil
    var weightKg: Double? = nil
    var lastUpdated: Date = Date()

    var bmi: Double? {
        guard let h = heightCm, let w = weightKg, h > 0 else { return nil }
        let meters = h / 100
        return w / (meters * meters)
    }

    enum AlcoholLevel: String, Codable, CaseIterable, Identifiable {
        case none = "Nada"
        case light = "Ligero"
        case moderate = "Moderado"
        case heavy = "Frecuente"
        var id: String { rawValue }
    }

    enum StressLevel: String, Codable, CaseIterable, Identifiable {
        case low = "Bajo"
        case medium = "Medio"
        case high = "Alto"
        var id: String { rawValue }
    }
}

// MARK: - Factor

struct BioAgeFactor: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let deltaYears: Double
    let valueLabel: String
}

// MARK: - Result

struct BioAgeResult: Hashable {
    let chronologicalAge: Double
    let biologicalAge: Double
    let factors: [BioAgeFactor]
    let completeness: Double
    let computedAt: Date

    var delta: Double { biologicalAge - chronologicalAge }
    var isYounger: Bool { delta < -0.1 }
    var isOlder: Bool { delta > 0.1 }

    var summary: String {
        let abs = Swift.abs(delta)
        if abs < 0.5 { return "Tu edad biológica coincide con tu edad real." }
        let years = String(format: "%.1f", abs)
        return isYounger ? "\(years) años más joven."
                         : "\(years) años por encima."
    }
}

// MARK: - Calculator

/// Transparent, linear biological age calculator.
/// Not a medical device — directional feedback only.
enum BioAgeCalculator {
    static func compute(
        inputs: BioAgeInputs,
        restingHR: Double?,
        hrv: Double?,
        steps: Int,
        sleepHours: Double
    ) -> BioAgeResult {
        let chrono = Double(inputs.chronologicalAge)
        var factors: [BioAgeFactor] = []
        var available = 0
        var needed = 0

        // Resting heart rate — ideal 55
        needed += 1
        if let rhr = restingHR, rhr > 0 {
            available += 1
            let delta = linear(rhr, ideal: 55, worst: 90, young: -2, old: 3)
            factors.append(.init(
                title: "Ritmo en reposo",
                subtitle: describe(delta, good: "Corazón eficiente.",
                                   bad: "Elevado.", neutral: "En rango."),
                icon: "heart.fill",
                deltaYears: delta,
                valueLabel: "\(Int(rhr)) bpm"))
        }

        // HRV — higher is better
        needed += 1
        if let v = hrv, v > 0 {
            available += 1
            let delta = linear(v, ideal: 70, worst: 25, young: -3, old: 3, lowerIsWorse: true)
            factors.append(.init(
                title: "Variabilidad cardíaca",
                subtitle: describe(delta, good: "Sistema nervioso resiliente.",
                                   bad: "Señal de estrés.", neutral: "Aceptable."),
                icon: "waveform.path.ecg",
                deltaYears: delta,
                valueLabel: "\(Int(v)) ms"))
        }

        // Steps — 10k ideal
        needed += 1
        available += 1
        let stepDelta = linear(Double(steps), ideal: 10_000, worst: 2_000,
                               young: -1.5, old: 2, lowerIsWorse: true)
        factors.append(.init(
            title: "Movimiento diario",
            subtitle: describe(stepDelta, good: "Cuerpo activo.",
                               bad: "Muy sedentario.", neutral: "Bien."),
            icon: "figure.walk",
            deltaYears: stepDelta,
            valueLabel: "\(steps) pasos"))

        // Sleep — 8h ideal
        needed += 1
        available += 1
        let sleepDelta = linear(sleepHours, ideal: 8, worst: 4.5,
                                young: -1.5, old: 2.5, lowerIsWorse: true)
        factors.append(.init(
            title: "Sueño",
            subtitle: describe(sleepDelta, good: "Descanso reparador.",
                               bad: "Falta sueño.", neutral: "Suficiente."),
            icon: "moon.stars.fill",
            deltaYears: sleepDelta,
            valueLabel: String(format: "%.1f h", sleepHours)))

        // Stress
        needed += 1
        available += 1
        let stressDelta: Double = {
            switch inputs.stress {
            case .low: return -1
            case .medium: return 0.5
            case .high: return 2.5
            }
        }()
        factors.append(.init(
            title: "Estrés percibido",
            subtitle: inputs.stress.rawValue,
            icon: "wind",
            deltaYears: stressDelta,
            valueLabel: inputs.stress.rawValue))

        // Alcohol
        needed += 1
        available += 1
        let alcoholDelta: Double = {
            switch inputs.alcohol {
            case .none: return -0.5
            case .light: return 0
            case .moderate: return 1
            case .heavy: return 3
            }
        }()
        factors.append(.init(
            title: "Alcohol",
            subtitle: inputs.alcohol.rawValue,
            icon: "wineglass",
            deltaYears: alcoholDelta,
            valueLabel: inputs.alcohol.rawValue))

        // Tobacco
        needed += 1
        available += 1
        let smokeDelta: Double = inputs.smokes ? 5 : -0.5
        factors.append(.init(
            title: "Tabaco",
            subtitle: inputs.smokes ? "Fumas actualmente." : "No fumas.",
            icon: "lungs.fill",
            deltaYears: smokeDelta,
            valueLabel: inputs.smokes ? "Sí" : "No"))

        // BMI (optional)
        if let bmi = inputs.bmi {
            available += 1
            needed += 1
            let delta: Double
            switch bmi {
            case ..<18.5: delta = 1.5
            case 18.5..<25: delta = -1
            case 25..<30: delta = 1.5
            default: delta = 3
            }
            factors.append(.init(
                title: "IMC",
                subtitle: bmi < 18.5 ? "Bajo."
                        : bmi < 25 ? "En rango."
                        : bmi < 30 ? "Sobrepeso." : "Obesidad.",
                icon: "scalemass",
                deltaYears: delta,
                valueLabel: String(format: "%.1f", bmi)))
        }

        let totalDelta = factors.reduce(0.0) { $0 + $1.deltaYears }
        let clamped = max(-15, min(15, totalDelta))
        let bio = max(14, chrono + clamped)

        return BioAgeResult(
            chronologicalAge: chrono,
            biologicalAge: bio,
            factors: factors.sorted { abs($0.deltaYears) > abs($1.deltaYears) },
            completeness: needed > 0 ? Double(available) / Double(needed) : 0,
            computedAt: Date()
        )
    }

    private static func linear(_ value: Double,
                               ideal: Double, worst: Double,
                               young: Double, old: Double,
                               lowerIsWorse: Bool = false) -> Double {
        if lowerIsWorse {
            if value >= ideal { return young }
            if value <= worst { return old }
            let t = (ideal - value) / (ideal - worst)
            return young + t * (old - young)
        } else {
            if value <= ideal { return young }
            if value >= worst { return old }
            let t = (value - ideal) / (worst - ideal)
            return young + t * (old - young)
        }
    }

    private static func describe(_ delta: Double,
                                 good: String, bad: String, neutral: String) -> String {
        if delta < -0.8 { return good }
        if delta > 0.8 { return bad }
        return neutral
    }
}

// MARK: - Storage

@Observable
final class BioAgeStore {
    static let shared = BioAgeStore()
    private let key = "adaptai.bioage.inputs.v1"

    var inputs: BioAgeInputs {
        didSet { save() }
    }

    private init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(BioAgeInputs.self, from: data) {
            inputs = decoded
        } else {
            inputs = BioAgeInputs()
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(inputs) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
