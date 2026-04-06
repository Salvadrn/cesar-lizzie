import SwiftUI
import NeuroNavKit

struct AssistantView: View {
    @Environment(AdaptiveEngine.self) private var engine
    @Environment(AuthService.self) private var authService
    @Environment(\.colorScheme) private var colorScheme
    @State private var vm = AssistantViewModel()

    private var level: Int { engine.currentLevel }
    private var isDark: Bool { colorScheme == .dark }

    private var userName: String {
        authService.currentProfile?.displayName.components(separatedBy: " ").first
            ?? (authService.isGuestMode ? "Invitado" : "Usuario")
    }

    var body: some View {
        VStack(spacing: 0) {
            // Chat messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: level <= 2 ? 16 : 12) {
                        if vm.messages.isEmpty {
                            welcomeCard
                                .padding(.top, 20)
                        }

                        ForEach(vm.messages) { message in
                            MessageBubble(
                                message: message,
                                level: level,
                                isDark: isDark
                            )
                            .id(message.id)
                        }

                        if vm.isLoading {
                            HStack {
                                TypingIndicator()
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .id("typing")
                        }
                    }
                    .padding(.vertical, 12)
                }
                .onChange(of: vm.messages.count) {
                    withAnimation {
                        proxy.scrollTo(vm.messages.last?.id ?? "typing", anchor: .bottom)
                    }
                }
            }

            Divider()

            // Quick suggestions (only when chat is empty)
            if vm.messages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(vm.suggestions(for: level)) { suggestion in
                            Button {
                                Task {
                                    await vm.sendQuickSuggestion(
                                        suggestion,
                                        complexityLevel: level,
                                        userName: userName
                                    )
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Text(suggestion.emoji)
                                    Text(suggestion.text)
                                        .font(level <= 2 ? .body.bold() : .subheadline)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Color.nnTint)
                                .foregroundStyle(.nnPrimary)
                                .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
            }

            // Input bar
            inputBar
        }
        .background(isDark ? Color.nnNightBG : Color(.systemGroupedBackground))
        .navigationTitle(level <= 2 ? "Addi" : "Asistente Addi")
        .navigationBarTitleDisplayMode(level <= 2 ? .inline : .large)
        .toolbar {
            if !vm.messages.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        vm.clearChat()
                    } label: {
                        Image(systemName: "trash")
                            .font(.subheadline)
                    }
                }
            }
        }
    }

    // MARK: - Welcome Card

    private var welcomeCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: level <= 2 ? 60 : 48))
                .foregroundStyle(.nnPrimary)

            if level <= 2 {
                Text("Hola \(userName)!")
                    .font(.title.bold())
                Text("Soy Addi. ¿Necesitas ayuda?")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            } else {
                Text("Hola \(userName), soy Addi")
                    .font(.title2.bold())
                Text("Tu asistente personal. Pregúntame lo que necesites sobre tus rutinas, medicamentos, o cualquier cosa.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(24)
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField(
                level <= 2 ? "Escribe aquí..." : "Escribe tu mensaje...",
                text: $vm.inputText,
                axis: .vertical
            )
            .lineLimit(1...4)
            .padding(12)
            .background(isDark ? Color(.systemGray5) : .white)
            .clipShape(RoundedRectangle(cornerRadius: 20))

            Button {
                Task {
                    await vm.sendMessage(
                        complexityLevel: level,
                        userName: userName
                    )
                }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: level <= 2 ? 44 : 36))
                    .foregroundStyle(.nnPrimary)
            }
            .disabled(vm.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage
    let level: Int
    let isDark: Bool

    var body: some View {
        HStack {
            if message.isFromUser { Spacer(minLength: 50) }

            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(level <= 2 ? .body : .subheadline)
                    .padding(14)
                    .background(
                        message.isFromUser
                            ? Color.nnPrimary
                            : (isDark ? Color(.systemGray5) : Color(.systemGray6))
                    )
                    .foregroundStyle(message.isFromUser ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if !message.isFromUser { Spacer(minLength: 50) }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var animating = false

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.nnMidGray)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animating ? 1.0 : 0.5)
                    .animation(
                        .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: animating
                    )
            }
        }
        .padding(14)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .onAppear { animating = true }
    }
}
