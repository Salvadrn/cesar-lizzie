import Foundation

actor JarvisService {
    static let shared = JarvisService()

    private let baseURL: String
    private let apiKey: String
    private var conversationId: String?

    init(
        baseURL: String = "https://jarvis.your-worker.workers.dev",
        apiKey: String = ""
    ) {
        self.baseURL = baseURL
        self.apiKey = apiKey
    }

    struct ChatResponse: Decodable {
        let response: String
        let conversationId: String
        let actions: [ActionResult]
    }

    struct ActionResult: Decodable {
        let tool: String
        let status: String
        let summary: String
    }

    func sendMessage(_ message: String, userId: String) async throws -> String {
        let url = URL(string: "\(baseURL)/api/chat/patient")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let formatter = ISO8601DateFormatter()
        let body: [String: Any] = [
            "message": message,
            "conversationId": conversationId as Any,
            "source": "patient",
            "userId": userId,
            "context": [
                "time": formatter.string(from: Date()),
                "timezone": "America/Mexico_City"
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw JarvisError.apiError
        }

        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
        self.conversationId = chatResponse.conversationId
        return chatResponse.response
    }

    func resetConversation() {
        conversationId = nil
    }

    enum JarvisError: Error {
        case apiError
    }
}
