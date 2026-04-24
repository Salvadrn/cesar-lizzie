import SwiftUI
import AdaptAiKit

/// Biological age — only shown to complexity level 5 users.
/// UI inspired by Soulspring: big number hero, eyebrows in small caps,
/// metric tiles with circular icon badges, minimal shadows.
struct BioAgeView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var store = BioAgeStore.shared
    @State private var health = HealthKitService.shared
    @State private var showingInputs = false

    private var isDark: Bool { colorScheme == .dark }

    private var result: BioAgeResult {
        BioAgeCalculator.compute(
            inputs: store.inputs,
            restingHR: health.restingHeartRate,
            hrv: nil,
            steps: health.stepsToday,
            sleepHours: health.sleepHoursLastNight ?? 7.0
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                hero
                summaryCard
                factorsSection
                lifestyleBox
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(
            LinearGradient(
                colors: [
                    Color.nnPrimary.opacity(isDark ? 0.15 : 0.08),
                    Color(.systemBackground),
                ],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Edad biológica")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingInputs) {
            NavigationStack {
                BioAgeInputsSheet(inputs: $store.inputs)
            }
        }
        .task { if health.isAuthorized { await health.fetchAll() } }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(spacing: 12) {
            eyebrow("Tu edad biológica")

            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 14)
                    .frame(width: 200, height: 200)

                Circle()
                    .trim(from: 0, to: max(0.05, min(result.completeness, 1)))
                    .stroke(
                        LinearGradient(
                            colors: [Color.nnPrimary, .nnGold],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 200, height: 200)

                VStack(spacing: 0) {
                    Text("\(Int(result.biologicalAge.rounded()))")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundStyle(isDark ? .white : .nnDarkText)
                    Text("años")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(1.8)
                }
            }
            .padding(.vertical, 8)

            Text(result.summary)
                .font(.nnHeadline)
                .foregroundStyle(result.isYounger ? .nnSuccess
                                 : result.isOlder ? .nnWarning : .primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
    }

    // MARK: - Summary

    private var summaryCard: some View {
        HStack(spacing: 0) {
            summaryStat(
                label: "Cronológica",
                value: "\(Int(result.chronologicalAge.rounded()))",
                tint: .secondary
            )
            Rectangle().fill(Color(.systemGray5)).frame(width: 1, height: 44)
            summaryStat(
                label: "Diferencia",
                value: formattedDelta,
                tint: result.isYounger ? .nnSuccess : result.isOlder ? .nnWarning : .primary
            )
            Rectangle().fill(Color(.systemGray5)).frame(width: 1, height: 44)
            summaryStat(
                label: "Completitud",
                value: "\(Int(result.completeness * 100))%",
                tint: .nnPrimary
            )
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(isDark ? Color.white.opacity(0.06) : Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var formattedDelta: String {
        let abs = Swift.abs(result.delta)
        let years = String(format: "%.1f", abs)
        if result.isYounger { return "−\(years)" }
        if result.isOlder { return "+\(years)" }
        return "0"
    }

    private func summaryStat(label: String, value: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(tint)
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Factors breakdown

    private var factorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Desglose", subtitle: "Qué está afectando tu edad biológica")

            VStack(spacing: 10) {
                ForEach(result.factors) { factor in
                    factorRow(factor)
                }
            }
        }
    }

    private func factorRow(_ factor: BioAgeFactor) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(factorTint(factor).opacity(0.18))
                    .frame(width: 42, height: 42)
                Image(systemName: factor.icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(factorTint(factor))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(factor.title)
                    .font(.nnSubheadline.weight(.semibold))
                Text(factor.subtitle)
                    .font(.nnCaption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(formattedFactorDelta(factor.deltaYears))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(factorTint(factor))
                Text(factor.valueLabel)
                    .font(.nnCaption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(isDark ? Color.white.opacity(0.06) : Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func factorTint(_ factor: BioAgeFactor) -> Color {
        if factor.deltaYears < -0.5 { return .nnSuccess }
        if factor.deltaYears > 0.5 { return .nnWarning }
        return .secondary
    }

    private func formattedFactorDelta(_ delta: Double) -> String {
        if Swift.abs(delta) < 0.1 { return "±0" }
        let sign = delta > 0 ? "+" : "−"
        return "\(sign)\(String(format: "%.1f", Swift.abs(delta)))a"
    }

    // MARK: - Lifestyle inputs

    private var lifestyleBox: some View {
        Button {
            showingInputs = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "slider.horizontal.3")
                    .font(.title3)
                    .foregroundStyle(.nnPrimary)
                    .frame(width: 40, height: 40)
                    .background(Color.nnPrimary.opacity(0.15))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("Actualizar datos")
                        .font(.nnSubheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("Edad, peso, estrés, hábitos")
                        .font(.nnCaption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(isDark ? Color.white.opacity(0.06) : Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, subtitle: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.nnHeadline.weight(.bold))
            if let subtitle {
                Text(subtitle)
                    .font(.nnCaption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func eyebrow(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .bold))
            .tracking(1.8)
            .foregroundStyle(.secondary)
    }
}

// MARK: - Inputs Sheet

struct BioAgeInputsSheet: View {
    @Binding var inputs: BioAgeInputs
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Datos básicos") {
                Stepper("Edad: \(inputs.chronologicalAge)", value: $inputs.chronologicalAge, in: 14...100)

                HStack {
                    Text("Altura (cm)")
                    Spacer()
                    TextField("170", value: $inputs.heightCm, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }

                HStack {
                    Text("Peso (kg)")
                    Spacer()
                    TextField("70", value: $inputs.weightKg, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
            }

            Section("Estilo de vida") {
                Picker("Estrés", selection: $inputs.stress) {
                    ForEach(BioAgeInputs.StressLevel.allCases) {
                        Text($0.rawValue).tag($0)
                    }
                }

                Picker("Alcohol", selection: $inputs.alcohol) {
                    ForEach(BioAgeInputs.AlcoholLevel.allCases) {
                        Text($0.rawValue).tag($0)
                    }
                }

                Toggle("Fumo actualmente", isOn: $inputs.smokes)
            }

            Section {
                Text("Tu edad biológica es una estimación basada en hábitos y señales del Apple Watch. No es un diagnóstico médico.")
                    .font(.nnCaption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Tus datos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Listo") {
                    inputs.lastUpdated = Date()
                    dismiss()
                }
                .bold()
            }
        }
    }
}
