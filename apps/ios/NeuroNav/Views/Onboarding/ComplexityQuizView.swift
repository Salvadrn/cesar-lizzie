import SwiftUI
import NeuroNavKit

struct ComplexityQuizView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.colorScheme) private var colorScheme
    @State private var currentQuestion = 0
    @State private var answers: [Int] = Array(repeating: -1, count: 10)
    @State private var isSaving = false
    let onComplete: () -> Void

    private var isDark: Bool { colorScheme == .dark }

    private let questions: [(question: String, icon: String, lowLabel: String, highLabel: String)] = [
        ("¿Qué tan cómodo te sientes usando un celular?", "iphone", "Nada cómodo", "Muy cómodo"),
        ("¿Cuánta información prefieres ver en pantalla?", "rectangle.grid.1x2", "Muy poca", "Toda la posible"),
        ("¿Qué tan bien sigues varios pasos a la vez?", "list.number", "Necesito uno a uno", "Varios sin problema"),
        ("¿Qué tan cómodo estás con botones pequeños?", "hand.tap.fill", "Prefiero grandes", "No me importa el tamaño"),
        ("¿Necesitas que la app te lea las instrucciones?", "speaker.wave.2.fill", "Sí, siempre", "No, prefiero leer"),
        ("¿Qué tanto dependes de los recordatorios?", "bell.fill", "Los necesito mucho", "Casi no los necesito"),
        ("¿Qué tan fácil te es concentrarte en una tarea?", "brain.head.profile.fill", "Me cuesta mucho", "Sin problemas"),
        ("¿Cómo te sientes con límites de tiempo?", "timer", "Me estresa mucho", "Me motiva"),
        ("¿Qué tan bien sigues instrucciones escritas?", "doc.text", "Necesito imágenes", "Leo sin problema"),
        ("¿Cuánta ayuda necesitas en tu día a día?", "figure.stand", "Mucha ayuda", "Soy independiente"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            header
            progressBar

            Spacer()
            questionCard
            Spacer()

            navigationButtons
        }
        .background(
            (isDark ? Color.nnNightBG : Color.nnLightBG).ignoresSafeArea()
        )
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button("Omitir") {
                onComplete()
            }
            .font(.nnSubheadline)
            .foregroundStyle(.nnMidGray)

            Spacer()

            Text("\(currentQuestion + 1) de \(questions.count)")
                .font(.nnCaption)
                .foregroundStyle(.nnMidGray)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.nnRule.opacity(isDark ? 0.3 : 1))
                    .frame(height: 6)

                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.nnPrimary)
                    .frame(width: geo.size.width * CGFloat(currentQuestion + 1) / CGFloat(questions.count), height: 6)
                    .animation(.easeInOut(duration: 0.3), value: currentQuestion)
            }
        }
        .frame(height: 6)
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }

    // MARK: - Question Card

    private var questionCard: some View {
        let q = questions[currentQuestion]
        return VStack(spacing: 28) {
            Image(systemName: q.icon)
                .font(.system(size: 40))
                .foregroundStyle(.nnPrimary)

            Text(q.question)
                .font(.nnTitle2)
                .foregroundStyle(isDark ? .white : .nnDarkText)
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            // 1-2-3-4 scale
            VStack(spacing: 12) {
                HStack(spacing: 0) {
                    ForEach(0..<4) { index in
                        scaleButton(value: index)
                    }
                }

                // Low/High labels
                HStack {
                    Text(q.lowLabel)
                        .font(.nnCaption)
                        .foregroundStyle(.nnMidGray)

                    Spacer()

                    Text(q.highLabel)
                        .font(.nnCaption)
                        .foregroundStyle(.nnMidGray)
                }
                .padding(.horizontal, 8)
            }
        }
        .padding(.horizontal, 24)
        .id(currentQuestion)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }

    private func scaleButton(value: Int) -> some View {
        let isSelected = answers[currentQuestion] == value
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                answers[currentQuestion] = value
            }
        } label: {
            Text("\(value + 1)")
                .font(.nnTitle2)
                .foregroundStyle(isSelected ? .white : (isDark ? .white.opacity(0.7) : .nnDarkText))
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(
                    isSelected
                        ? Color.nnPrimary
                        : (isDark ? Color.white.opacity(0.08) : Color.white)
                )
                .clipShape(RoundedRectangle(cornerRadius: value == 0 ? 12 : (value == 3 ? 12 : 4)))
                .overlay(
                    RoundedRectangle(cornerRadius: value == 0 ? 12 : (value == 3 ? 12 : 4))
                        .stroke(
                            isSelected ? Color.nnPrimary : (isDark ? Color.white.opacity(0.12) : Color.nnRule),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: isSelected ? Color.nnPrimary.opacity(0.3) : .clear, radius: 6, y: 2)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 3)
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
                        .frame(width: 48, height: 48)
                        .background(Color.nnPrimary.opacity(isDark ? 0.15 : 0.1))
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
                HStack(spacing: 6) {
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
                .padding(.horizontal, 28)
                .frame(height: 48)
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

        let answered = answers.filter { $0 >= 0 }
        guard !answered.isEmpty else {
            onComplete()
            return
        }

        let total = answered.reduce(0, +)
        let maxPossible = answered.count * 3
        let ratio = Double(total) / Double(maxPossible)

        let level: Int
        switch ratio {
        case 0..<0.2: level = 1
        case 0.2..<0.4: level = 2
        case 0.4..<0.6: level = 3
        case 0.6..<0.8: level = 4
        default: level = 5
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
