import SwiftUI
import NeuroNavKit

struct ComplexityQuizView: View {
    @Environment(AuthService.self) private var authService
    @State private var currentQuestion = 0
    @State private var answers: [Int] = Array(repeating: -1, count: 10)
    @State private var isSaving = false
    let onComplete: () -> Void

    private let questions: [(question: String, icon: String, options: [String])] = [
        (
            "¿Que tan comodo te sientes usando un celular?",
            "iphone",
            ["Necesito mucha ayuda", "A veces necesito ayuda", "Me siento comodo", "Lo uso sin problemas"]
        ),
        (
            "¿Cuanta informacion prefieres ver en la pantalla?",
            "rectangle.grid.1x2",
            ["Muy poquita, solo lo esencial", "Poca, lo basico", "Normal", "Toda la informacion disponible"]
        ),
        (
            "¿Como prefieres que te guien los pasos?",
            "list.number",
            ["Uno a la vez, con voz", "Uno a la vez", "Varios pasos a la vez", "Solo una lista, yo me organizo"]
        ),
        (
            "¿Que tan grandes prefieres los botones?",
            "hand.tap.fill",
            ["Muy grandes", "Grandes", "Normales", "Pequenos esta bien"]
        ),
        (
            "¿Necesitas que la app te lea las instrucciones?",
            "speaker.wave.2.fill",
            ["Si, siempre", "A veces", "Solo si yo lo pido", "No, prefiero leer"]
        ),
        (
            "¿Como manejas los recordatorios?",
            "bell.fill",
            ["Necesito muchos recordatorios", "Algunos recordatorios me ayudan", "Solo los importantes", "Casi no los necesito"]
        ),
        (
            "¿Que tanto puedes concentrarte en una tarea?",
            "brain.head.profile.fill",
            ["Me cuesta mucho", "A veces me distraigo", "Generalmente bien", "Sin problemas"]
        ),
        (
            "¿Como te sientes con el tiempo limitado?",
            "timer",
            ["Me estresa mucho", "Prefiero sin limite", "No me molesta", "Me motiva"]
        ),
        (
            "¿Puedes seguir instrucciones escritas?",
            "doc.text",
            ["Necesito dibujos o fotos", "Textos cortos con iconos", "Textos normales", "Textos largos sin problema"]
        ),
        (
            "¿Cuanta ayuda necesitas en tu dia a dia?",
            "figure.stand",
            ["Mucha ayuda constante", "Ayuda en algunas cosas", "Poca ayuda", "Soy bastante independiente"]
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Omitir") {
                    onComplete()
                }
                .font(.nnSubheadline)
                .foregroundStyle(.nnMidGray)

                Spacer()

                Text("\(currentQuestion + 1) / \(questions.count)")
                    .font(.nnCaption)
                    .foregroundStyle(.nnMidGray)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            // Progress
            ProgressView(value: Double(currentQuestion + 1), total: Double(questions.count))
                .tint(.nnPrimary)
                .padding(.horizontal, 24)
                .padding(.top, 12)

            Spacer()

            // Question
            questionCard

            Spacer()

            // Navigation
            navigationButtons
        }
        .background(Color.nnLightBG)
    }

    // MARK: - Question Card

    private var questionCard: some View {
        let q = questions[currentQuestion]
        return VStack(spacing: 24) {
            Image(systemName: q.icon)
                .font(.system(size: 44))
                .foregroundStyle(.nnPrimary)

            Text(q.question)
                .font(.nnTitle2)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            VStack(spacing: 10) {
                ForEach(Array(q.options.enumerated()), id: \.offset) { index, option in
                    optionButton(text: option, index: index)
                }
            }
        }
        .padding(.horizontal, 24)
        .id(currentQuestion) // triggers transition
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }

    private func optionButton(text: String, index: Int) -> some View {
        let isSelected = answers[currentQuestion] == index
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                answers[currentQuestion] = index
            }
        } label: {
            HStack(spacing: 14) {
                Circle()
                    .fill(isSelected ? Color.nnPrimary : Color.nnRule)
                    .frame(width: 24, height: 24)
                    .overlay {
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }

                Text(text)
                    .font(.nnBody)
                    .foregroundStyle(isSelected ? .nnDarkText : .nnMidGray)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(isSelected ? Color.nnPrimary.opacity(0.08) : .white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.nnPrimary.opacity(0.3) : Color.nnRule, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Navigation

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if currentQuestion > 0 {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentQuestion -= 1
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.nnHeadline)
                        .foregroundStyle(.nnPrimary)
                        .frame(width: 52, height: 52)
                        .background(Color.nnPrimary.opacity(0.1))
                        .clipShape(Circle())
                }
            }

            Spacer()

            Button {
                if currentQuestion < questions.count - 1 {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentQuestion += 1
                    }
                } else {
                    Task { await saveResult() }
                }
            } label: {
                HStack(spacing: 8) {
                    if isSaving {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(currentQuestion == questions.count - 1 ? "Finalizar" : "Siguiente")
                            .font(.nnHeadline)
                        if currentQuestion < questions.count - 1 {
                            Image(systemName: "chevron.right")
                                .font(.nnCaption)
                        }
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .frame(height: 52)
                .background(answers[currentQuestion] >= 0 ? Color.nnPrimary : Color.nnMidGray)
                .clipShape(Capsule())
            }
            .disabled(answers[currentQuestion] < 0 || isSaving)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }

    // MARK: - Calculate & Save

    private func saveResult() async {
        isSaving = true

        // Each answer is 0-3, mapping to complexity preference
        // 0 = needs most help (level 1), 3 = most independent (level 4-5)
        let answered = answers.filter { $0 >= 0 }
        guard !answered.isEmpty else {
            onComplete()
            return
        }

        let total = answered.reduce(0, +)
        let maxPossible = answered.count * 3
        let ratio = Double(total) / Double(maxPossible)

        // Map ratio to complexity level 1-5
        let level: Int
        switch ratio {
        case 0..<0.2: level = 1   // Essential
        case 0.2..<0.4: level = 2 // Simple
        case 0.4..<0.6: level = 3 // Standard
        case 0.6..<0.8: level = 4 // Detailed
        default: level = 5        // Full
        }

        do {
            let update = ProfileUpdate(currentComplexity: level)
            try await APIClient.shared.updateProfile(update)
            await authService.restoreSession()
        } catch {
            print("Quiz save error: \(error)")
        }

        isSaving = false
        onComplete()
    }
}
