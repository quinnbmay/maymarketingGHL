//
//  ElevenLabsService.swift
//  Jarvis
//
//  Created by Quinn May on 7/25/25.
//

import Foundation
import AVFoundation
import Combine
import Network

class ElevenLabsService: ObservableObject {
    private let baseURL = "https://api.elevenlabs.io/v1"
    private let apiKey: String
    private var audioPlayer: AVAudioPlayer?
    private var webSocketConnection: URLSessionWebSocketTask?
    private var isWebSocketConnected = false
    
    @Published var isSynthesizing = false
    @Published var error: String?
    @Published var availableVoices: [Voice] = []
    @Published var currentVoice: Voice?
    @Published var usageStats: UsageStats?
    @Published var isStreaming = false
    @Published var streamingProgress: Double = 0.0
    
    // Conversational AI properties
    @Published var isConversationalAIEnabled = false
    @Published var conversationalAgent: ConversationalAIAgent?
    
    init(apiKey: String = JARVISConfiguration.elevenLabsAPIKey) {
        self.apiKey = apiKey
        print("🎙️ ElevenLabsService initialized with API key: \(String(apiKey.prefix(10)))...")
        loadAvailableVoices()
        setupConversationalAI()
    }
    
    // MARK: - Standard Text-to-Speech
    
    func synthesizeSpeech(text: String, voiceID: String = JARVISConfiguration.ElevenLabs.defaultVoiceID) async throws -> Data {
        print("🎙️ Synthesizing speech: \(text.prefix(50))...")
        
        guard !text.isEmpty else {
            throw ElevenLabsError.emptyText
        }
        
        await MainActor.run {
            isSynthesizing = true
            error = nil
        }
        
        let url = URL(string: "\(baseURL)/text-to-speech/\(voiceID)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "xi-api-key")
        
        let requestBody = SynthesisRequest(
            text: text,
            model_id: "eleven_monolingual_v1",
            voice_settings: VoiceSettings(
                stability: JARVISConfiguration.ElevenLabs.defaultStability,
                similarity_boost: JARVISConfiguration.ElevenLabs.defaultSimilarityBoost,
                style: JARVISConfiguration.ElevenLabs.defaultStyle,
                use_speaker_boost: JARVISConfiguration.ElevenLabs.defaultSpeakerBoost
            )
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            await MainActor.run {
                isSynthesizing = false
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ElevenLabsError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                print("✅ Speech synthesis successful")
                return data
            } else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ Speech synthesis failed: \(errorMessage)")
                await MainActor.run {
                    error = "Synthesis failed: \(errorMessage)"
                }
                throw ElevenLabsError.apiError(errorMessage)
            }
        } catch {
            await MainActor.run {
                isSynthesizing = false
                self.error = error.localizedDescription
            }
            throw error
        }
    }
    
    // MARK: - Text-to-Dialogue Streaming (Multi-Character)
    
    func synthesizeDialogue(dialogueInputs: [DialogueInput], modelID: String = "eleven_v3") async throws -> Data {
        print("🎭 Synthesizing dialogue with \(dialogueInputs.count) inputs...")
        
        guard !dialogueInputs.isEmpty else {
            throw ElevenLabsError.emptyText
        }
        
        await MainActor.run {
            isSynthesizing = true
            error = nil
        }
        
        let url = URL(string: "\(baseURL)/text-to-dialogue/stream")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "xi-api-key")
        
        let requestBody = DialogueRequest(
            inputs: dialogueInputs,
            model_id: modelID,
            settings: DialogueSettings(
                pronunciation_dictionary_locators: nil,
                seed: nil
            )
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            await MainActor.run {
                isSynthesizing = false
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ElevenLabsError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                print("✅ Dialogue synthesis successful")
                return data
            } else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ Dialogue synthesis failed: \(errorMessage)")
                await MainActor.run {
                    error = "Dialogue synthesis failed: \(errorMessage)"
                }
                throw ElevenLabsError.apiError(errorMessage)
            }
        } catch {
            await MainActor.run {
                isSynthesizing = false
                self.error = error.localizedDescription
            }
            throw error
        }
    }
    
    // MARK: - WebSocket Multi-Stream Input (Real-time)
    
    func startWebSocketStream(voiceID: String = JARVISConfiguration.ElevenLabs.defaultVoiceID) {
        let webSocketURL = "wss://api.elevenlabs.io/v1/text-to-speech/\(voiceID)/multi-stream-input"
        guard let url = URL(string: webSocketURL) else {
            print("❌ Invalid WebSocket URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "xi-api-key")
        
        let session = URLSession(configuration: .default)
        webSocketConnection = session.webSocketTask(with: request)
        webSocketConnection?.resume()
        
        isWebSocketConnected = true
        print("🔌 WebSocket connection started")
        
        // Start receiving messages
        receiveWebSocketMessages()
    }
    
    func sendTextToWebSocket(_ text: String) {
        guard isWebSocketConnected, let webSocket = webSocketConnection else {
            print("❌ WebSocket not connected")
            return
        }
        
        let message = WebSocketMessage.sendText(SendTextMulti(
            text: text,
            try_trigger_generation: true,
            voice_settings: VoiceSettings(
                stability: JARVISConfiguration.ElevenLabs.defaultStability,
                similarity_boost: JARVISConfiguration.ElevenLabs.defaultSimilarityBoost,
                style: JARVISConfiguration.ElevenLabs.defaultStyle,
                use_speaker_boost: JARVISConfiguration.ElevenLabs.defaultSpeakerBoost
            )
        ))
        
        do {
            let data = try JSONEncoder().encode(message)
            let webSocketMessage = URLSessionWebSocketTask.Message.data(data)
            webSocket.send(webSocketMessage) { error in
                if let error = error {
                    print("❌ Failed to send WebSocket message: \(error)")
                } else {
                    print("✅ Text sent to WebSocket: \(text.prefix(30))...")
                }
            }
        } catch {
            print("❌ Failed to encode WebSocket message: \(error)")
        }
    }
    
    private func receiveWebSocketMessages() {
        guard let webSocket = webSocketConnection else { return }
        
        webSocket.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleWebSocketMessage(message)
                // Continue receiving messages
                self?.receiveWebSocketMessages()
            case .failure(let error):
                print("❌ WebSocket receive error: \(error)")
                self?.isWebSocketConnected = false
            }
        }
    }
    
    private func handleWebSocketMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .data(let data):
            do {
                let audioOutput = try JSONDecoder().decode(AudioOutputMulti.self, from: data)
                print("🎵 Received audio chunk: \(audioOutput.audio_chunk?.count ?? 0) bytes")
                
                // Process the audio chunk
                if let audioData = audioOutput.audio_chunk {
                    Task {
                        await self.playAudio(audioData)
                    }
                }
                
                // Update progress
                if let progress = audioOutput.progress {
                    Task { @MainActor in
                        self.streamingProgress = progress
                    }
                }
                
            } catch {
                print("❌ Failed to decode WebSocket message: \(error)")
            }
        case .string(let string):
            print("📝 Received string message: \(string)")
        @unknown default:
            print("❓ Unknown WebSocket message type")
        }
    }
    
    func closeWebSocketConnection() {
        webSocketConnection?.cancel()
        webSocketConnection = nil
        isWebSocketConnected = false
        print("🔌 WebSocket connection closed")
    }
    
    // MARK: - Speech-to-Text
    
    func convertSpeechToText(audioData: Data) async throws -> String {
        print("🎤 Converting speech to text...")
        
        let url = URL(string: "\(baseURL)/speech-to-text/convert")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "xi-api-key")
        
        // Create multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add audio file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"audio.wav\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add model_id
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("eleven_english_sts_v2\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ElevenLabsError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            let sttResponse = try JSONDecoder().decode(STTResponse.self, from: data)
            print("✅ Speech-to-text successful: \(sttResponse.text)")
            return sttResponse.text
        } else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ElevenLabsError.apiError(errorMessage)
        }
    }
    
    func playAudio(_ audioData: Data) async {
        do {
            audioPlayer = try AVAudioPlayer(data: audioData)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            print("🔊 Playing synthesized audio")
        } catch {
            print("❌ Failed to play audio: \(error)")
            await MainActor.run {
                self.error = "Failed to play audio: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Conversational AI Integration
    
    private func setupConversationalAI() {
        isConversationalAIEnabled = JARVISConfiguration.ElevenLabs.ConversationalAI.enabled
        
        if isConversationalAIEnabled && !JARVISConfiguration.ElevenLabs.ConversationalAI.agentID.isEmpty {
            conversationalAgent = ConversationalAIAgent(
                id: JARVISConfiguration.ElevenLabs.ConversationalAI.agentID,
                name: "JARVIS Assistant",
                voiceID: JARVISConfiguration.ElevenLabs.defaultVoiceID,
                languageModel: JARVISConfiguration.ElevenLabs.LanguageModels.gpt4o
            )
            print("🤖 Conversational AI enabled with agent: \(conversationalAgent?.name ?? "Unknown")")
        }
    }
    
    func startConversation() async throws -> String {
        guard isConversationalAIEnabled, let agent = conversationalAgent else {
            throw ElevenLabsError.conversationalAINotEnabled
        }
        
        // This would integrate with ElevenLabs Conversational AI WebSocket API
        // For now, we'll return a placeholder
        print("🤖 Starting conversation with agent: \(agent.name)")
        return "Conversation started with \(agent.name)"
    }
    
    func sendConversationMessage(_ message: String) async throws -> String {
        guard isConversationalAIEnabled, let agent = conversationalAgent else {
            throw ElevenLabsError.conversationalAINotEnabled
        }
        
        // This would send messages to the Conversational AI agent
        // For now, we'll return a placeholder response
        print("🤖 Sending message to agent: \(agent.name) - \(message)")
        return "Agent response: \(message)"
    }
    
    // MARK: - Voice Management
    
    private func loadAvailableVoices() {
        Task {
            do {
                let voices = try await fetchVoices()
                await MainActor.run {
                    self.availableVoices = voices
                    if let defaultVoice = voices.first(where: { $0.voice_id == JARVISConfiguration.ElevenLabs.defaultVoiceID }) {
                        self.currentVoice = defaultVoice
                    }
                }
            } catch {
                print("❌ Failed to load voices: \(error)")
            }
        }
    }
    
    private func fetchVoices() async throws -> [Voice] {
        let url = URL(string: "\(baseURL)/voices")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "xi-api-key")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ElevenLabsError.invalidResponse
        }
        
        let voicesResponse = try JSONDecoder().decode(VoicesResponse.self, from: data)
        return voicesResponse.voices
    }
    
    func changeVoice(to voiceID: String) {
        if let newVoice = availableVoices.first(where: { $0.voice_id == voiceID }) {
            currentVoice = newVoice
            print("🎙️ Changed voice to: \(newVoice.name)")
        }
    }
    
    // MARK: - Usage Statistics
    
    func fetchUsageStats() async {
        do {
            let url = URL(string: "\(baseURL)/user/subscription")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "xi-api-key")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw ElevenLabsError.invalidResponse
            }
            
            let subscription = try JSONDecoder().decode(SubscriptionResponse.self, from: data)
            await MainActor.run {
                self.usageStats = UsageStats(
                    characterCount: subscription.character_count,
                    characterLimit: subscription.character_limit,
                    canExtendCharacterLimit: subscription.can_extend_character_limit,
                    allowedToExtendCharacterLimit: subscription.allowed_to_extend_character_limit,
                    nextCharacterCountResetUnix: subscription.next_character_count_reset_unix,
                    voiceLimit: subscription.voice_limit,
                    professionalVoiceLimit: subscription.professional_voice_limit,
                    canExtendVoiceLimit: subscription.can_extend_voice_limit,
                    canUseProfessionalVoices: subscription.can_use_professional_voices,
                    canUseInstantVoiceCloning: subscription.can_use_instant_voice_cloning,
                    canUseFineTuning: subscription.can_use_fine_tuning,
                    canUseProfessionalVoiceLimit: subscription.can_use_professional_voice_limit
                )
            }
        } catch {
            print("❌ Failed to fetch usage stats: \(error)")
        }
    }
}

// MARK: - Data Models

struct SynthesisRequest: Codable {
    let text: String
    let model_id: String
    let voice_settings: VoiceSettings
}

struct VoiceSettings: Codable {
    let stability: Double
    let similarity_boost: Double
    let style: Double
    let use_speaker_boost: Bool
}

// MARK: - Dialogue Models

struct DialogueRequest: Codable {
    let inputs: [DialogueInput]
    let model_id: String
    let settings: DialogueSettings
}

struct DialogueInput: Codable {
    let text: String
    let voice_id: String
}

struct DialogueSettings: Codable {
    let pronunciation_dictionary_locators: [PronunciationDictionaryLocator]?
    let seed: Int?
}

struct PronunciationDictionaryLocator: Codable {
    let id: String
    let version_id: String
}

// MARK: - WebSocket Models

enum WebSocketMessage: Codable {
    case initializeConnection(InitializeConnectionMulti)
    case initialiseContext(InitialiseContext)
    case sendText(SendTextMulti)
    case flushContext(FlushContextClient)
    case closeContext(CloseContextClient)
    case closeSocket(CloseSocketClient)
    case keepContextAlive(KeepContextAlive)
}

struct InitializeConnectionMulti: Codable {
    let connection_id: String
    let voice_id: String
    let model_id: String
    let language_code: String?
    let enable_logging: Bool
    let enable_ssml_parsing: Bool
    let output_format: String?
    let inactivity_timeout: Int
    let sync_alignment: Bool
    let auto_mode: Bool
    let apply_text_normalization: String
    let seed: Int?
}

struct InitialiseContext: Codable {
    let connection_id: String
    let voice_id: String
    let model_id: String
    let language_code: String?
    let enable_logging: Bool
    let enable_ssml_parsing: Bool
    let output_format: String?
    let inactivity_timeout: Int
    let sync_alignment: Bool
    let auto_mode: Bool
    let apply_text_normalization: String
    let seed: Int?
}

struct SendTextMulti: Codable {
    let text: String
    let try_trigger_generation: Bool
    let voice_settings: VoiceSettings
}

struct FlushContextClient: Codable {
    let connection_id: String
    let voice_id: String
    let model_id: String
}

struct CloseContextClient: Codable {
    let connection_id: String
    let voice_id: String
}

struct CloseSocketClient: Codable {
    let connection_id: String
}

struct KeepContextAlive: Codable {
    let connection_id: String
    let voice_id: String
}

struct AudioOutputMulti: Codable {
    let audio_chunk: Data?
    let progress: Double?
    let alignment: [Alignment]?
    let is_final: Bool?
}

struct Alignment: Codable {
    let char_start: Int
    let char_end: Int
    let start_time: Double
    let end_time: Double
}

// MARK: - Speech-to-Text Models

struct STTResponse: Codable {
    let text: String
}

// MARK: - Voice Models

struct Voice: Codable, Identifiable {
    let voice_id: String
    let name: String
    let samples: [Sample]?
    let category: String
    let fine_tuning: FineTuning?
    let labels: [String: String]
    let description: String?
    let preview_url: String?
    let available_for_tiers: [String]
    let settings: VoiceSettings?
    let sharing: Sharing?
    let high_quality_base_model_ids: [String]
    let safety_control: String?
    let safety_label: String?
    let voice_verification: VoiceVerification?
    
    var id: String { voice_id }
}

struct Sample: Codable {
    let sample_id: String
    let file_name: String
    let mime_type: String
    let size_bytes: Int
    let hash: String
}

struct FineTuning: Codable {
    let model_id: String
    let is_allowed_to_fine_tune: Bool
    let fine_tuning_requested_at: String?
    let finetuning_request_status: String?
    let verification_failures: [String]
    let verification_attempts_count: Int
    let manual_verification_requested: Bool
    let language: String?
    let is_serving: Bool
    let all_tiers_available: Bool
}

struct Sharing: Codable {
    let status: String
    let history_item_sample_id: String?
    let original_voice_id: String?
    let public_owner_id: String?
    let liked_by_count: Int
    let cloned_by_count: Int
    let name: String?
    let description: String?
    let labels: [String: String]
    let linked_user: LinkedUser?
    let instagram_username: String?
    let twitter_username: String?
    let youtube_username: String?
    let tiktok_username: String?
}

struct LinkedUser: Codable {
    let user_id: String
    let name: String
    let instagram_username: String?
    let twitter_username: String?
    let youtube_username: String?
    let tiktok_username: String?
}

struct VoiceVerification: Codable {
    let requires_verification: Bool
    let is_verified: Bool
    let verification_failures: [String]
    let verification_attempts_count: Int
    let language: String?
    let verification_attempts: [VerificationAttempt]
}

struct VerificationAttempt: Codable {
    let text: String
    let date_unix: Int
    let accepted: Bool
    let similarity: Double
    let levenshtein_distance: Int
    let recording: Recording
}

struct Recording: Codable {
    let recording_id: String
    let mime_type: String
    let size_bytes: Int
    let upload_date_unix: Int
    let transcription: String
}

struct VoicesResponse: Codable {
    let voices: [Voice]
}

struct SubscriptionResponse: Codable {
    let character_count: Int
    let character_limit: Int
    let can_extend_character_limit: Bool
    let allowed_to_extend_character_limit: Bool
    let next_character_count_reset_unix: Int
    let voice_limit: Int
    let professional_voice_limit: Int
    let can_extend_voice_limit: Bool
    let can_use_professional_voices: Bool
    let can_use_instant_voice_cloning: Bool
    let can_use_fine_tuning: Bool
    let can_use_professional_voice_limit: Bool
}

struct UsageStats {
    let characterCount: Int
    let characterLimit: Int
    let canExtendCharacterLimit: Bool
    let allowedToExtendCharacterLimit: Bool
    let nextCharacterCountResetUnix: Int
    let voiceLimit: Int
    let professionalVoiceLimit: Int
    let canExtendVoiceLimit: Bool
    let canUseProfessionalVoices: Bool
    let canUseInstantVoiceCloning: Bool
    let canUseFineTuning: Bool
    let canUseProfessionalVoiceLimit: Bool
    
    var characterUsagePercentage: Double {
        guard characterLimit > 0 else { return 0 }
        return Double(characterCount) / Double(characterLimit) * 100
    }
    
    var remainingCharacters: Int {
        return max(0, characterLimit - characterCount)
    }
}

// MARK: - Error Types

enum ElevenLabsError: Error, LocalizedError {
    case emptyText
    case invalidResponse
    case apiError(String)
    case conversationalAINotEnabled
    case networkError
    case webSocketError(String)
    
    var errorDescription: String? {
        switch self {
        case .emptyText:
            return "Text cannot be empty"
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let message):
            return "API Error: \(message)"
        case .conversationalAINotEnabled:
            return "Conversational AI is not enabled"
        case .networkError:
            return "Network connection error"
        case .webSocketError(let message):
            return "WebSocket Error: \(message)"
        }
    }
}

// MARK: - Conversational AI Agent

class ConversationalAIAgent: ObservableObject {
    let id: String
    let name: String
    let voiceID: String
    let languageModel: String
    let knowledgeBase: [String]
    let tools: [String]
    let isEnabled: Bool
    
    @Published var isConnected = false
    @Published var lastMessage: String = ""
    @Published var connectionStatus: String = "Disconnected"
    
    init(id: String, name: String, voiceID: String = JARVISConfiguration.ElevenLabs.defaultVoiceID, 
         languageModel: String = JARVISConfiguration.ElevenLabs.LanguageModels.gpt4o, 
         knowledgeBase: [String] = [], tools: [String] = [], isEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.voiceID = voiceID
        self.languageModel = languageModel
        self.knowledgeBase = knowledgeBase
        self.tools = tools
        self.isEnabled = isEnabled
    }
    
    func connect() {
        print("🤖 Connecting to Conversational AI Agent: \(name)")
        isConnected = true
        connectionStatus = "Connected"
    }
    
    func disconnect() {
        print("🤖 Disconnecting from Conversational AI Agent: \(name)")
        isConnected = false
        connectionStatus = "Disconnected"
    }
    
    func sendMessage(_ message: String) async throws -> String {
        guard isConnected else {
            throw ElevenLabsError.conversationalAINotEnabled
        }
        
        print("🤖 Sending message to agent: \(message)")
        lastMessage = message
        
        // Placeholder response - in real implementation, this would send to ElevenLabs API
        return "Agent \(name) received: \(message)"
    }
} 