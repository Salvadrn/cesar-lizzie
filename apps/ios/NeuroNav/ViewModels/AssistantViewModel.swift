import Foundation
import NeuroNavKit

@Observable
final class AssistantViewModel {
    var messages: [ChatMessage] = []
    var inputText = ""
    var isLoading = false
    var errorMessage: String?

    private let claudeService = ClaudeService.shared

    /// Quick-action suggestions based on complexity level
    func suggestions(for level: Int) -> [QuickSuggestion] {
        if level <= 2 {
            return [
                QuickSuggestion(emoji: "💊", text: "Medicinas"),
                QuickSuggestion(emoji: "📋", text: "Rutinas"),
                QuickSuggestion(emoji: "😊", text: "Cómo estoy"),
                QuickSuggestion(emoji: "🆘", text: "Ayuda"),
            ]
        } else {
            return [
                QuickSuggestion(emoji: "💊", text: "¿Qué medicinas me tocan?"),
                QuickSuggestion(emoji: "📋", text: "¿Cuál es mi siguiente rutina?"),
                QuickSuggestion(emoji: "🧠", text: "Necesito un consejo"),
                QuickSuggestion(emoji: "😊", text: "¿Cómo va mi progreso?"),
            ]
        }
    }

    func sendMessage(complexityLevel: Int, userName: String) async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let userMessage = ChatMessage(text: text, isFromUser: true)
        messages.append(userMessage)
        inputText = ""
        isLoading = true
        errorMessage = nil

        do {
            let response = try await claudeService.sendMessage(
                userMessage: text,
                conversationHistory: messages,
                complexityLevel: complexityLevel,
                userName: userName
            )
            let assistantMessage = ChatMessage(text: response, isFromUser: false)
            messages.append(assistantMessage)
        } catch {
            errorMessage = error.localizedDescription
            let errorMsg = ChatMessage(
                text: complexityLevel <= 2
                    ? "No pude responder. Intenta de nuevo."
                    : "Lo siento, hubo un error al procesar tu mensaje. Por favor intenta de nuevo.",
                isFromUser: false
            )
            messages.append(errorMsg)
        }

        isLoading = false
    }

    func sendQuickSuggestion(_ suggestion: QuickSuggestion, complexityLevel: Int, userName: String) async {
        inputText = suggestion.text
        await sendMessage(complexityLevel: complexityLevel, userName: userName)
    }

    func clearChat() {
        messages.removeAll()
        errorMessage = nil
    }
}

struct QuickSuggestion: Identifiable {
    let id = UUID()
    let emoji: String
    let text: String
}
