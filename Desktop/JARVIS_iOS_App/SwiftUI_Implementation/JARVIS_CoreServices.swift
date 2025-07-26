// JARVIS iOS App - Core Services Implementation

import Foundation
import AVFoundation
import Speech
import Combine
import CryptoKit
import LocalAuthentication

// MARK: - Audio Engine Service
class AudioEngineService: ObservableObject {
    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioPlayer: AVAudioPlayer?
    
    @Published var isRecording = false
    @Published var transcribedText = ""
    @Published var audioLevels: [Float] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupAudioSession()
        requestPermissions()
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func requestPermissions() {
        AVAudioApplication.requestRecordPermission { granted in
            if granted {
                SFSpeechRecognizer.requestAuthorization { status in
                    DispatchQueue.main.async {
                        print("Speech recognition authorization: \(status)")
                    }
                }
            }
        }
    }
    
    func startRecording() async throws {
        guard !isRecording else { return }
        
        // Cancel any existing recognition task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Configure audio session for recording
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw AudioError.recognitionRequestFailed
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = true // For privacy
        
        // Setup audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
            self?.processAudioBuffer(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        // Start recognition
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                if let result = result {
                    self?.transcribedText = result.bestTranscription.formattedString
                }
                
                if error != nil || result?.isFinal == true {
                    self?.stopRecording()
                }
            }
        }
        
        isRecording = true
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        isRecording = false
        
        // Reset audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        } catch {
            print("Failed to reset audio session: \(error)")
        }
    }
    
    func playAudio(data: Data) async throws {
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            throw AudioError.playbackFailed
        }
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        
        let channelDataValue = channelData.pointee
        let frameLength = Int(buffer.frameLength)
        
        var sum: Float = 0
        for i in 0..<frameLength {
            sum += abs(channelDataValue[i])
        }
        
        let averageLevel = sum / Float(frameLength)
        
        DispatchQueue.main.async {
            self.audioLevels.append(averageLevel * 10) // Scale for visualization
            if self.audioLevels.count > 50 {
                self.audioLevels.removeFirst()
            }
        }
    }
}

// MARK: - ElevenLabs API Service
class ElevenLabsService: ObservableObject {
    private let baseURL = "https://api.elevenlabs.io/v1"
    private let session: URLSession
    private let apiKey: String
    private let voiceId: String
    
    init(apiKey: String, voiceId: String) {
        self.apiKey = apiKey
        self.voiceId = voiceId
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }
    
    func synthesizeSpeech(text: String, voiceSettings: VoiceSettings = .default) async throws -> Data {
        let url = URL(string: "\(baseURL)/text-to-speech/\(voiceId)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        
        let payload = TTSRequest(
            text: text,
            voiceSettings: voiceSettings
        )
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(payload)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ElevenLabsError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            return data
        case 401:
            throw ElevenLabsError.invalidAPIKey
        case 429:
            throw ElevenLabsError.rateLimitExceeded
        default:
            throw ElevenLabsError.serverError(httpResponse.statusCode)
        }
    }
    
    func getVoices() async throws -> [Voice] {
        let url = URL(string: "\(baseURL)/voices")!
        
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ElevenLabsError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let voicesResponse = try decoder.decode(VoicesResponse.self, from: data)
        
        return voicesResponse.voices
    }
    
    func streamSpeech(text: String, voiceSettings: VoiceSettings = .default) -> AsyncThrowingStream<Data, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let url = URL(string: "\(baseURL)/text-to-speech/\(voiceId)/stream")!
                    
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
                    
                    let payload = TTSRequest(text: text, voiceSettings: voiceSettings)
                    let encoder = JSONEncoder()
                    encoder.keyEncodingStrategy = .convertToSnakeCase
                    request.httpBody = try encoder.encode(payload)
                    
                    let (asyncBytes, response) = try await session.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode == 200 else {
                        continuation.finish(throwing: ElevenLabsError.invalidResponse)
                        return
                    }
                    
                    for try await byte in asyncBytes {
                        continuation.yield(Data([byte]))
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

// MARK: - MCP Bridge Service
class MCPBridgeService: ObservableObject {
    private let serverURL: URL
    private let session: URLSession
    private var webSocketTask: URLSessionWebSocketTask?
    
    @Published var isConnected = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    
    private var messageId: Int = 0
    private var pendingRequests: [Int: CheckedContinuation<MCPResponse, Error>] = [:]
    
    init(serverURL: URL) {
        self.serverURL = serverURL
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        self.session = URLSession(configuration: config)
    }
    
    func connect() async throws {
        connectionStatus = .connecting
        
        webSocketTask = session.webSocketTask(with: serverURL)
        webSocketTask?.resume()
        
        // Start listening for messages
        Task {
            await listenForMessages()
        }
        
        // Send initial handshake
        try await sendHandshake()
        
        connectionStatus = .connected
        isConnected = true
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        connectionStatus = .disconnected
        isConnected = false
    }
    
    func sendCommand(_ command: String, context: [String: Any] = [:]) async throws -> MCPResponse {
        guard isConnected else {
            throw MCPError.notConnected
        }
        
        messageId += 1
        let message = MCPMessage(
            id: messageId,
            method: "execute_command",
            params: [
                "command": command,
                "context": context
            ]
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            pendingRequests[messageId] = continuation
            
            Task {
                do {
                    let encoder = JSONEncoder()
                    let data = try encoder.encode(message)
                    let messageString = String(data: data, encoding: .utf8)!
                    
                    try await webSocketTask?.send(.string(messageString))
                } catch {
                    pendingRequests.removeValue(forKey: messageId)
                    continuation.resume(throwing: error)
                }
            }
            
            // Add timeout
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                if let continuation = self.pendingRequests.removeValue(forKey: messageId) {
                    continuation.resume(throwing: MCPError.timeout)
                }
            }
        }
    }
    
    private func sendHandshake() async throws {
        let handshake = MCPMessage(
            id: 0,
            method: "initialize",
            params: [
                "protocolVersion": "1.0",
                "clientInfo": [
                    "name": "JARVIS-iOS",
                    "version": "1.0.0"
                ]
            ]
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(handshake)
        let messageString = String(data: data, encoding: .utf8)!
        
        try await webSocketTask?.send(.string(messageString))
    }
    
    private func listenForMessages() async {
        guard let webSocketTask = webSocketTask else { return }
        
        do {
            for try await message in webSocketTask.messages {
                switch message {
                case .string(let text):
                    await handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        await handleMessage(text)
                    }
                @unknown default:
                    break
                }
            }
        } catch {
            await MainActor.run {
                connectionStatus = .error(error)
                isConnected = false
            }
        }
    }
    
    private func handleMessage(_ messageText: String) async {
        do {
            let decoder = JSONDecoder()
            let data = messageText.data(using: .utf8)!
            let response = try decoder.decode(MCPResponse.self, from: data)
            
            if let continuation = pendingRequests.removeValue(forKey: response.id) {
                continuation.resume(returning: response)
            }
        } catch {
            print("Failed to decode MCP response: \(error)")
        }
    }
}

// MARK: - Secure Configuration Manager
class SecureConfigurationManager: ObservableObject {
    private let keychain = Keychain(service: "com.jarvis.ios")
    private let encryptionKey: SymmetricKey
    
    @Published var isConfigured = false
    
    private enum Keys {
        static let elevenLabsAPIKey = "elevenlabs_api_key"
        static let mcpServerURL = "mcp_server_url"
        static let encryptionSalt = "encryption_salt"
        static let biometricEnabled = "biometric_enabled"
    }
    
    init() throws {
        // Generate or retrieve encryption key
        if let existingKey = keychain.getData(Keys.encryptionSalt) {
            self.encryptionKey = SymmetricKey(data: existingKey)
        } else {
            self.encryptionKey = SymmetricKey(size: .bits256)
            keychain.set(encryptionKey.withUnsafeBytes { Data($0) }, forKey: Keys.encryptionSalt)
        }
        
        checkConfiguration()
    }
    
    func setElevenLabsAPIKey(_ apiKey: String) throws {
        let encrypted = try encrypt(apiKey)
        keychain.set(encrypted, forKey: Keys.elevenLabsAPIKey)
        checkConfiguration()
    }
    
    func getElevenLabsAPIKey() throws -> String? {
        guard let encryptedData = keychain.getData(Keys.elevenLabsAPIKey) else {
            return nil
        }
        return try decrypt(encryptedData)
    }
    
    func setMCPServerURL(_ url: String) throws {
        let encrypted = try encrypt(url)
        keychain.set(encrypted, forKey: Keys.mcpServerURL)
        checkConfiguration()
    }
    
    func getMCPServerURL() throws -> String? {
        guard let encryptedData = keychain.getData(Keys.mcpServerURL) else {
            return nil
        }
        return try decrypt(encryptedData)
    }
    
    func setBiometricEnabled(_ enabled: Bool) {
        keychain.set(enabled, forKey: Keys.biometricEnabled)
    }
    
    func isBiometricEnabled() -> Bool {
        return keychain.getBool(Keys.biometricEnabled) ?? false
    }
    
    private func encrypt(_ string: String) throws -> Data {
        let data = Data(string.utf8)
        let sealedBox = try AES.GCM.seal(data, using: encryptionKey)
        return sealedBox.combined!
    }
    
    private func decrypt(_ data: Data) throws -> String {
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        let decryptedData = try AES.GCM.open(sealedBox, using: encryptionKey)
        return String(data: decryptedData, encoding: .utf8)!
    }
    
    private func checkConfiguration() {
        DispatchQueue.main.async {
            self.isConfigured = (try? self.getElevenLabsAPIKey()) != nil &&
                              (try? self.getMCPServerURL()) != nil
        }
    }
}

// MARK: - Biometric Authentication Manager
class BiometricAuthManager: ObservableObject {
    private let context = LAContext()
    
    @Published var isBiometricAvailable = false
    @Published var biometricType: LABiometryType = .none
    
    init() {
        checkBiometricAvailability()
    }
    
    func checkBiometricAvailability() {
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            isBiometricAvailable = true
            biometricType = context.biometryType
        } else {
            isBiometricAvailable = false
            biometricType = .none
        }
    }
    
    func authenticateUser(reason: String = "Authenticate to access JARVIS") async throws -> Bool {
        guard isBiometricAvailable else {
            throw BiometricError.notAvailable
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return success
        } catch let error as LAError {
            switch error.code {
            case .userCancel:
                throw BiometricError.userCancel
            case .userFallback:
                throw BiometricError.userFallback
            case .biometryNotAvailable:
                throw BiometricError.notAvailable
            case .biometryNotEnrolled:
                throw BiometricError.notEnrolled
            case .biometryLockout:
                throw BiometricError.lockout
            default:
                throw BiometricError.authenticationFailed
            }
        }
    }
}

// MARK: - Conversation Manager
class ConversationManager: ObservableObject {
    @Published var conversations: [ConversationEntry] = []
    @Published var currentSession: ConversationSession?
    
    private let storageService: ConversationStorageService
    private let maxHistoryCount = 50
    
    init(storageService: ConversationStorageService) {
        self.storageService = storageService
        loadRecentConversations()
    }
    
    func startNewSession() {
        currentSession = ConversationSession(id: UUID(), startTime: Date())
    }
    
    func addUserMessage(_ text: String) {
        let entry = ConversationEntry(
            text: text,
            isUser: true,
            timestamp: Date()
        )
        
        conversations.append(entry)
        currentSession?.addEntry(entry)
        
        // Limit history
        if conversations.count > maxHistoryCount {
            conversations.removeFirst(conversations.count - maxHistoryCount)
        }
    }
    
    func addAIResponse(_ text: String) {
        let entry = ConversationEntry(
            text: text,
            isUser: false,
            timestamp: Date()
        )
        
        conversations.append(entry)
        currentSession?.addEntry(entry)
        
        // Save session
        if let session = currentSession {
            Task {
                try await storageService.saveSession(session)
            }
        }
    }
    
    func clearConversations() {
        conversations.removeAll()
        currentSession = nil
    }
    
    private func loadRecentConversations() {
        Task {
            do {
                let recentSessions = try await storageService.getRecentSessions(limit: 5)
                let allEntries = recentSessions.flatMap { $0.entries }
                
                await MainActor.run {
                    self.conversations = Array(allEntries.suffix(maxHistoryCount))
                }
            } catch {
                print("Failed to load conversations: \(error)")
            }
        }
    }
}

// MARK: - Background Audio Session Manager
class BackgroundAudioSessionManager: ObservableObject {
    @Published var isBackgroundEnabled = false
    @Published var backgroundMode: BackgroundMode = .disabled
    
    private let audioSession = AVAudioSession.sharedInstance()
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    enum BackgroundMode {
        case disabled
        case voiceActivation
        case continuousListening
    }
    
    func enableBackgroundMode(_ mode: BackgroundMode) {
        backgroundMode = mode
        
        switch mode {
        case .disabled:
            disableBackgroundAudio()
        case .voiceActivation:
            enableVoiceActivation()
        case .continuousListening:
            enableContinuousListening()
        }
    }
    
    private func enableVoiceActivation() {
        do {
            try audioSession.setCategory(
                .playAndRecord,
                mode: .voiceChat,
                options: [.allowBluetooth, .mixWithOthers]
            )
            try audioSession.setActive(true)
            
            isBackgroundEnabled = true
        } catch {
            print("Failed to enable background voice activation: \(error)")
        }
    }
    
    private func enableContinuousListening() {
        do {
            try audioSession.setCategory(
                .playAndRecord,
                mode: .measurement,
                options: [.allowBluetooth, .duckOthers]
            )
            try audioSession.setActive(true)
            
            // Request background processing
            backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
                self?.endBackgroundTask()
            }
            
            isBackgroundEnabled = true
        } catch {
            print("Failed to enable continuous listening: \(error)")
        }
    }
    
    private func disableBackgroundAudio() {
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            isBackgroundEnabled = false
            endBackgroundTask()
        } catch {
            print("Failed to disable background audio: \(error)")
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
}

// MARK: - Supporting Types and Errors
enum AudioError: Error {
    case recognitionRequestFailed
    case playbackFailed
    case permissionDenied
}

enum ElevenLabsError: Error {
    case invalidAPIKey
    case invalidResponse
    case rateLimitExceeded
    case serverError(Int)
}

enum MCPError: Error {
    case notConnected
    case timeout
    case serverError
    case invalidResponse
}

enum BiometricError: Error {
    case notAvailable
    case notEnrolled
    case userCancel
    case userFallback
    case lockout
    case authenticationFailed
}

enum ConnectionStatus {
    case disconnected
    case connecting
    case connected
    case error(Error)
}

// MARK: - Data Models
struct TTSRequest: Codable {
    let text: String
    let voiceSettings: VoiceSettings
}

struct VoiceSettings: Codable {
    let stability: Double
    let similarityBoost: Double
    let style: Double
    let useSpeakerBoost: Bool
    
    static let `default` = VoiceSettings(
        stability: 0.75,
        similarityBoost: 0.75,
        style: 0.0,
        useSpeakerBoost: true
    )
}

struct Voice: Codable, Identifiable {
    let voiceId: String
    let name: String
    let previewUrl: String?
    let category: String
    
    var id: String { voiceId }
}

struct VoicesResponse: Codable {
    let voices: [Voice]
}

struct MCPMessage: Codable {
    let id: Int
    let method: String
    let params: [String: Any]
    
    enum CodingKeys: String, CodingKey {
        case id, method, params
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(method, forKey: .method)
        
        let jsonData = try JSONSerialization.data(withJSONObject: params)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        try container.encode(AnyCodable(jsonObject), forKey: .params)
    }
}

struct MCPResponse: Codable {
    let id: Int
    let result: [String: Any]?
    let error: MCPErrorResponse?
    
    enum CodingKeys: String, CodingKey {
        case id, result, error
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        error = try container.decodeIfPresent(MCPErrorResponse.self, forKey: .error)
        
        if let resultData = try container.decodeIfPresent(Data.self, forKey: .result) {
            result = try JSONSerialization.jsonObject(with: resultData) as? [String: Any]
        } else {
            result = nil
        }
    }
}

struct MCPErrorResponse: Codable {
    let code: Int
    let message: String
}

struct ConversationSession: Identifiable {
    let id: UUID
    let startTime: Date
    var entries: [ConversationEntry] = []
    
    mutating func addEntry(_ entry: ConversationEntry) {
        entries.append(entry)
    }
}

// Helper for encoding Any values
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if let value = value as? String {
            try container.encode(value)
        } else if let value = value as? Int {
            try container.encode(value)
        } else if let value = value as? Double {
            try container.encode(value)
        } else if let value = value as? Bool {
            try container.encode(value)
        } else if let value = value as? [Any] {
            try container.encode(value.map(AnyCodable.init))
        } else if let value = value as? [String: Any] {
            try container.encode(value.mapValues(AnyCodable.init))
        } else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Cannot encode value"))
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let value = try? container.decode(String.self) {
            self.value = value
        } else if let value = try? container.decode(Int.self) {
            self.value = value
        } else if let value = try? container.decode(Double.self) {
            self.value = value
        } else if let value = try? container.decode(Bool.self) {
            self.value = value
        } else if let value = try? container.decode([AnyCodable].self) {
            self.value = value.map(\.value)
        } else if let value = try? container.decode([String: AnyCodable].self) {
            self.value = value.mapValues(\.value)
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Cannot decode value"))
        }
    }
}

// Simple Keychain wrapper
class Keychain {
    private let service: String
    
    init(service: String) {
        self.service = service
    }
    
    func set(_ data: Data, forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func set(_ value: Bool, forKey key: String) {
        let data = Data([value ? 1 : 0])
        set(data, forKey: key)
    }
    
    func getData(_ key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        return status == errSecSuccess ? result as? Data : nil
    }
    
    func getBool(_ key: String) -> Bool? {
        guard let data = getData(key), let byte = data.first else { return nil }
        return byte == 1
    }
}

// Protocol for conversation storage
protocol ConversationStorageService {
    func saveSession(_ session: ConversationSession) async throws
    func getRecentSessions(limit: Int) async throws -> [ConversationSession]
    func deleteSession(_ sessionId: UUID) async throws
}