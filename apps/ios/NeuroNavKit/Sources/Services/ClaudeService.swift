import Foundation

/// Service for communicating with the Claude API (Anthropic)
@Observable
public final class ClaudeService {
    public static let shared = ClaudeService()

    public var isLoading = false

    // Store API key in Keychain in production; here we use a config constant
    private let apiKey: String = {
        // Read from environment or Info.plist in production
        Bundle.main.object(forInfoDictionaryKey: "CLAUDE_API_KEY") as? String ?? ""
    }()

    private let baseURL = "https://api.anthropic.com/v1/messages"
    private let model = "claude-sonnet-4-20250514"

    public init() {}

    /// Send a message to Claude with adaptive system prompt based on complexity level
    public func sendMessage(
        userMessage: String,
        conversationHistory: [ChatMessage],
        complexityLevel: Int,
        userName: String
    ) async throws -> String {
        isLoading = true
        defer { isLoading = false }

        let systemPrompt = buildSystemPrompt(
            complexityLevel: complexityLevel,
            userName: userName
        )

        var messages: [[String: String]] = []
        for msg in conversationHistory.suffix(20) {
            messages.append([
                "role": msg.isFromUser ? "user" : "assistant",
                "content": msg.text
            ])
        }
        messages.append(["role": "user", "content": userMessage])

        let body: [String: Any] = [
            "model": model,
            "max_tokens": complexityLevel <= 2 ? 256 : 1024,
            "system": systemPrompt,
            "messages": messages
        ]

        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw ClaudeError.apiError("Error del servidor: \(statusCode)")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstBlock = content.first,
              let text = firstBlock["text"] as? String else {
            throw ClaudeError.decodingError
        }

        return text
    }

    private func buildSystemPrompt(complexityLevel: Int, userName: String) -> String {
        let basePrompt = """
        Eres un asistente amable y paciente llamado "Addi" que ayuda a \(userName) con sus actividades diarias.
        Siempre respondes en español. Eres parte de la app AdaptAi, una herramienta para personas con discapacidades cognitivas.
        """

        switch complexityLevel {
        case 1:
            return basePrompt + """

            IMPORTANTE: El usuario tiene nivel de complejidad 1 (esencial).
            - Usa oraciones MUY cortas y simples (máximo 10 palabras por oración)
            - Usa emojis para ayudar a comunicar
            - No uses palabras complicadas
            - Sé muy directo y claro
            - Responde en máximo 2-3 oraciones
            """
        case 2:
            return basePrompt + """

            El usuario tiene nivel de complejidad 2 (simple).
            - Usa oraciones cortas y claras
            - Puedes usar emojis ocasionalmente
            - Evita tecnicismos
            - Responde en máximo 3-4 oraciones
            """
        case 3:
            return basePrompt + """

            El usuario tiene nivel de complejidad 3 (estándar).
            - Habla de forma natural y amigable
            - Puedes dar explicaciones moderadas
            - Responde de forma concisa pero completa
            """
        default:
            return basePrompt + """

            El usuario tiene nivel de complejidad \(complexityLevel) (detallado).
            - Puedes dar respuestas más elaboradas
            - Incluye detalles cuando sea relevante
            - Mantén un tono amigable y profesional
            """
        }
    }
}

public enum ClaudeError: Error, LocalizedError {
    case apiError(String)
    case decodingError
    case noApiKey

    public var errorDescription: String? {
        switch self {
        case .apiError(let msg): return msg
        case .decodingError: return "No se pudo procesar la respuesta"
        case .noApiKey: return "Falta la clave de API"
        }
    }
}

/// A single chat message
public struct ChatMessage: Identifiable, Codable {
    public let id: String
    public let text: String
    public let isFromUser: Bool
    public let timestamp: Date

    public init(id: String = UUID().uuidString, text: String, isFromUser: Bool, timestamp: Date = Date()) {
        self.id = id
        self.text = text
        self.isFromUser = isFromUser
        self.timestamp = timestamp
    }
}
