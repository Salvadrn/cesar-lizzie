import SwiftUI
import AVFoundation
import Speech
import NeuroNavKit

struct RobotChatView: View {
    @Environment(AuthService.self) private var authService
    @State private var messages: [(role: String, text: String)] = []
    @State private var isListening = false
    @State private var isProcessing = false
    @State private var currentTranscript = ""
    @State private var errorMessage: String?

    private let synthesizer = AVSpeechSynthesizer()

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(messages.enumerated()), id: \.offset) { index, msg in
                            chatBubble(role: msg.role, text: msg.text)
                                .id(index)
                        }

                        if isProcessing {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("JARVIS esta pensando...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                        }

                        if !currentTranscript.isEmpty {
                            chatBubble(role: "user", text: currentTranscript)
                                .opacity(0.6)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) {
                    withAnimation {
                        proxy.scrollTo(messages.count - 1, anchor: .bottom)
                    }
                }
            }

            // Error banner
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(.red)
            }

            // Mic button
            Button {
                if isListening {
                    stopListening()
                } else {
                    startListening()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(isListening ? Color.red : Color.blue)
                        .frame(width: 80, height: 80)
                        .shadow(color: isListening ? .red.opacity(0.4) : .blue.opacity(0.4), radius: 10)

                    Image(systemName: isListening ? "stop.fill" : "mic.fill")
                        .font(.title)
                        .foregroundStyle(.white)
                }
            }
            .disabled(isProcessing)
            .padding(.vertical, 20)
        }
        .navigationTitle("Hablar con JARVIS")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            requestSpeechPermission()
        }
    }

    // MARK: - Chat Bubble

    private func chatBubble(role: String, text: String) -> some View {
        HStack {
            if role == "user" { Spacer() }

            Text(text)
                .font(.body)
                .padding(12)
                .background(role == "user" ? Color.blue.opacity(0.15) : Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .frame(maxWidth: 280, alignment: role == "user" ? .trailing : .leading)

            if role != "user" { Spacer() }
        }
    }

    // MARK: - Speech Recognition

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "es-MX"))
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var audioEngine = AVAudioEngine()

    private func requestSpeechPermission() {
        SFSpeechRecognizer.requestAuthorization { _ in }
    }

    private func startListening() {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            errorMessage = "Reconocimiento de voz no disponible"
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        try? audioEngine.start()
        isListening = true
        currentTranscript = ""

        recognitionTask = recognizer.recognitionTask(with: request) { result, error in
            if let result = result {
                currentTranscript = result.bestTranscription.formattedString

                if result.isFinal {
                    stopListening()
                    let text = result.bestTranscription.formattedString
                    if !text.isEmpty {
                        sendToJarvis(text)
                    }
                }
            }

            if error != nil {
                stopListening()
            }
        }

        // Auto-stop after 8 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
            if isListening {
                stopListening()
                if !currentTranscript.isEmpty {
                    sendToJarvis(currentTranscript)
                }
            }
        }
    }

    private func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionTask?.cancel()
        recognitionTask = nil
        isListening = false
    }

    // MARK: - JARVIS API

    private func sendToJarvis(_ text: String) {
        let userText = text
        currentTranscript = ""
        messages.append((role: "user", text: userText))
        isProcessing = true
        errorMessage = nil

        Task {
            do {
                let userId = (try? await APIClient.shared.currentUserId()) ?? ""
                let response = try await JarvisService.shared.sendMessage(userText, userId: userId)
                messages.append((role: "assistant", text: response))
                speak(response)
            } catch {
                errorMessage = "Error al comunicar con JARVIS"
                messages.append((role: "assistant", text: "Disculpa, no pude procesar tu pregunta."))
            }
            isProcessing = false
        }
    }

    // MARK: - TTS

    private func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "es-MX")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 0.95
        synthesizer.speak(utterance)
    }
}
