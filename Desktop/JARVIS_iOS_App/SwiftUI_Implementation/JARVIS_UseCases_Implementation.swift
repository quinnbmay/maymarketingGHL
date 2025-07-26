// JARVIS iOS App - Use Cases Implementation

import Foundation
import Combine
import AVFoundation

// MARK: - Process Voice Command Use Case
class ProcessVoiceCommandUseCase {
    private let mcpBridge: MCPBridgeService
    private let conversationManager: ConversationManager
    private let contextProvider: ContextProvider
    private let commandProcessor: CommandProcessor
    
    init(
        mcpBridge: MCPBridgeService,
        conversationManager: ConversationManager,
        contextProvider: ContextProvider = DefaultContextProvider(),
        commandProcessor: CommandProcessor = DefaultCommandProcessor()
    ) {
        self.mcpBridge = mcpBridge
        self.conversationManager = conversationManager
        self.contextProvider = contextProvider
        self.commandProcessor = commandProcessor
    }
    
    func execute(command: String) async throws -> AIResponse {
        // Add user message to conversation
        conversationManager.addUserMessage(command)
        
        // Get current context
        let context = await contextProvider.getCurrentContext()
        
        // Process command locally first (for quick responses)
        if let localResponse = await commandProcessor.processLocally(command) {
            let response = AIResponse(
                text: localResponse.text,
                confidence: localResponse.confidence,
                isLocal: true,
                metadata: localResponse.metadata
            )
            
            conversationManager.addAIResponse(response.text)
            return response
        }
        
        // Send to MCP server for AI processing
        let mcpResponse = try await mcpBridge.sendCommand(command, context: context.toDictionary())
        
        guard let responseText = mcpResponse.result?["text"] as? String else {
            throw ProcessingError.invalidResponse
        }
        
        let confidence = mcpResponse.result?["confidence"] as? Double ?? 0.8
        let metadata = mcpResponse.result?["metadata"] as? [String: Any] ?? [:]
        
        let response = AIResponse(
            text: responseText,
            confidence: confidence,
            isLocal: false,
            metadata: metadata
        )
        
        conversationManager.addAIResponse(response.text)
        return response
    }
}

// MARK: - Synthesize Speech Use Case
class SynthesizeSpeechUseCase {
    private let elevenLabsService: ElevenLabsService
    private let cacheManager: AudioCacheManager
    private let voiceProfileManager: VoiceProfileManager
    
    init(
        elevenLabsService: ElevenLabsService,
        cacheManager: AudioCacheManager = AudioCacheManager(),
        voiceProfileManager: VoiceProfileManager = VoiceProfileManager()
    ) {
        self.elevenLabsService = elevenLabsService
        self.cacheManager = cacheManager
        self.voiceProfileManager = voiceProfileManager
    }
    
    func execute(text: String, options: SynthesisOptions = .default) async throws -> AudioData {
        // Check cache first
        let cacheKey = generateCacheKey(text: text, options: options)
        if let cachedAudio = await cacheManager.getCachedAudio(for: cacheKey) {
            return cachedAudio
        }
        
        // Get voice settings from profile
        let voiceSettings = voiceProfileManager.getCurrentVoiceSettings()
        
        // Synthesize speech
        let audioData = try await elevenLabsService.synthesizeSpeech(
            text: text,
            voiceSettings: voiceSettings
        )
        
        let result = AudioData(
            data: audioData,
            format: .mpeg,
            duration: estimateAudioDuration(data: audioData),
            text: text
        )
        
        // Cache the result
        if options.shouldCache {
            await cacheManager.cacheAudio(result, for: cacheKey)
        }
        
        return result
    }
    
    func streamSpeech(text: String, options: SynthesisOptions = .default) -> AsyncThrowingStream<AudioChunk, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let voiceSettings = voiceProfileManager.getCurrentVoiceSettings()
                    let audioStream = elevenLabsService.streamSpeech(text: text, voiceSettings: voiceSettings)
                    
                    var chunkIndex = 0
                    for try await data in audioStream {
                        let chunk = AudioChunk(
                            data: data,
                            index: chunkIndex,
                            isLast: false
                        )
                        continuation.yield(chunk)
                        chunkIndex += 1
                    }
                    
                    // Mark the last chunk
                    let finalChunk = AudioChunk(
                        data: Data(),
                        index: chunkIndex,
                        isLast: true
                    )
                    continuation.yield(finalChunk)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    private func generateCacheKey(text: String, options: SynthesisOptions) -> String {
        let voiceId = voiceProfileManager.activeProfile?.elevenLabsVoiceId ?? "default"
        return "\(voiceId)_\(text.hashValue)_\(options.hashValue)"
    }
    
    private func estimateAudioDuration(data: Data) -> TimeInterval {
        // Rough estimation: 1 second per 24KB at 24kHz mono
        return Double(data.count) / 24000.0
    }
}

// MARK: - Manage Conversation Use Case
class ManageConversationUseCase {
    private let conversationManager: ConversationManager
    private let storageService: ConversationStorageService
    private let analyticsService: AnalyticsService
    
    init(
        conversationManager: ConversationManager,
        storageService: ConversationStorageService,
        analyticsService: AnalyticsService = AnalyticsService()
    ) {
        self.conversationManager = conversationManager
        self.storageService = storageService
        self.analyticsService = analyticsService
    }
    
    func startNewConversation() async throws {
        conversationManager.startNewSession()
        
        // Log analytics
        analyticsService.trackEvent("conversation_started", properties: [
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    func endCurrentConversation() async throws {
        guard let session = conversationManager.currentSession else {
            throw ConversationError.noActiveSession
        }
        
        // Save the session
        try await storageService.saveSession(session)
        
        // Log analytics
        analyticsService.trackEvent("conversation_ended", properties: [
            "duration": Date().timeIntervalSince(session.startTime),
            "message_count": session.entries.count
        ])
        
        // Clear current session
        conversationManager.clearConversations()
    }
    
    func getConversationHistory(limit: Int = 10) async throws -> [ConversationSession] {
        return try await storageService.getRecentSessions(limit: limit)
    }
    
    func deleteConversation(sessionId: UUID) async throws {
        try await storageService.deleteSession(sessionId)
        
        analyticsService.trackEvent("conversation_deleted", properties: [
            "session_id": sessionId.uuidString
        ])
    }
    
    func exportConversation(sessionId: UUID, format: ExportFormat) async throws -> Data {
        let sessions = try await storageService.getRecentSessions(limit: 100)
        guard let session = sessions.first(where: { $0.id == sessionId }) else {
            throw ConversationError.sessionNotFound
        }
        
        switch format {
        case .json:
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            return try encoder.encode(session)
            
        case .text:
            let content = session.entries.map { entry in
                let speaker = entry.isUser ? "User" : "JARVIS"
                let timestamp = DateFormatter.shared.string(from: entry.timestamp)
                return "[\(timestamp)] \(speaker): \(entry.text)"
            }.joined(separator: "\n")
            
            return content.data(using: .utf8) ?? Data()
            
        case .markdown:
            let content = generateMarkdownReport(for: session)
            return content.data(using: .utf8) ?? Data()
        }
    }
    
    private func generateMarkdownReport(for session: ConversationSession) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        var markdown = """
        # JARVIS Conversation Report
        
        **Session ID:** \(session.id.uuidString)
        **Date:** \(formatter.string(from: session.startTime))
        **Duration:** \(formatDuration(from: session.startTime, to: Date()))
        **Messages:** \(session.entries.count)
        
        ---
        
        """
        
        for entry in session.entries {
            let speaker = entry.isUser ? "**User**" : "**JARVIS**"
            let time = DateFormatter.timeOnlyFormatter.string(from: entry.timestamp)
            markdown += "\n### \(speaker) (\(time))\n\n\(entry.text)\n"
        }
        
        return markdown
    }
    
    private func formatDuration(from start: Date, to end: Date) -> String {
        let duration = end.timeIntervalSince(start)
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        return "\(minutes)m \(seconds)s"
    }
}

// MARK: - Context Provider
protocol ContextProvider {
    func getCurrentContext() async -> UserContext
}

class DefaultContextProvider: ContextProvider {
    private let locationManager = LocationManager()
    private let calendarManager = CalendarManager()
    private let deviceInfoProvider = DeviceInfoProvider()
    
    func getCurrentContext() async -> UserContext {
        async let location = getLocation()
        async let upcomingEvents = getUpcomingEvents()
        async let deviceInfo = getDeviceInfo()
        async let environmentInfo = getEnvironmentInfo()
        
        return await UserContext(
            location: location,
            upcomingEvents: upcomingEvents,
            deviceInfo: deviceInfo,
            environmentInfo: environmentInfo,
            timestamp: Date()
        )
    }
    
    private func getLocation() async -> LocationInfo? {
        return await locationManager.getCurrentLocation()
    }
    
    private func getUpcomingEvents() async -> [CalendarEvent] {
        return await calendarManager.getUpcomingEvents(hours: 24)
    }
    
    private func getDeviceInfo() async -> DeviceInfo {
        return await deviceInfoProvider.getDeviceInfo()
    }
    
    private func getEnvironmentInfo() async -> EnvironmentInfo {
        return EnvironmentInfo(
            timeOfDay: TimeOfDay.current,
            batteryLevel: UIDevice.current.batteryLevel,
            networkType: NetworkMonitor.shared.connectionType,
            isLowPowerModeEnabled: ProcessInfo.processInfo.isLowPowerModeEnabled
        )
    }
}

// MARK: - Command Processor
protocol CommandProcessor {
    func processLocally(_ command: String) async -> LocalCommandResult?
}

class DefaultCommandProcessor: CommandProcessor {
    private let intentClassifier = IntentClassifier()
    private let entityExtractor = EntityExtractor()
    private let quickResponseHandler = QuickResponseHandler()
    
    func processLocally(_ command: String) async -> LocalCommandResult? {
        // Classify intent
        let intent = await intentClassifier.classify(command)
        
        // Check if we can handle this locally
        guard quickResponseHandler.canHandle(intent) else {
            return nil
        }
        
        // Extract entities
        let entities = await entityExtractor.extract(from: command, intent: intent)
        
        // Generate quick response
        let response = await quickResponseHandler.generateResponse(
            intent: intent,
            entities: entities,
            command: command
        )
        
        return LocalCommandResult(
            text: response.text,
            confidence: response.confidence,
            metadata: response.metadata,
            intent: intent,
            entities: entities
        )
    }
}

// MARK: - Intent Classification
class IntentClassifier {
    private let patterns: [Intent: [String]] = [
        .greeting: ["hello", "hi", "hey", "good morning", "good afternoon", "good evening"],
        .time: ["what time", "current time", "time is it"],
        .weather: ["weather", "temperature", "forecast", "rain", "sunny"],
        .reminder: ["remind me", "set reminder", "don't forget"],
        .timer: ["set timer", "start timer", "timer for"],
        .music: ["play music", "play song", "music", "spotify"],
        .question: ["what is", "who is", "how to", "why", "when"],
        .farewell: ["goodbye", "bye", "see you", "farewell"]
    ]
    
    func classify(_ command: String) async -> Intent {
        let lowercaseCommand = command.lowercased()
        
        for (intent, keywords) in patterns {
            for keyword in keywords {
                if lowercaseCommand.contains(keyword) {
                    return intent
                }
            }
        }
        
        return .unknown
    }
}

// MARK: - Entity Extraction
class EntityExtractor {
    private let naturalLanguageProcessor = NaturalLanguageProcessor()
    
    func extract(from text: String, intent: Intent) async -> [String: Any] {
        return await naturalLanguageProcessor.extractEntities(from: text, for: intent)
    }
}

// MARK: - Quick Response Handler
class QuickResponseHandler {
    private let localResponses: [Intent: [String]] = [
        .greeting: [
            "Hello! How can I assist you today?",
            "Hi there! What can I do for you?",
            "Good to see you! How may I help?"
        ],
        .time: [
            "The current time is {time}",
            "It's {time} right now"
        ],
        .farewell: [
            "Goodbye! Have a great day!",
            "See you later!",
            "Take care!"
        ]
    ]
    
    func canHandle(_ intent: Intent) -> Bool {
        return localResponses.keys.contains(intent)
    }
    
    func generateResponse(intent: Intent, entities: [String: Any], command: String) async -> QuickResponse {
        guard let responses = localResponses[intent] else {
            return QuickResponse(text: "I'm not sure how to help with that.", confidence: 0.3, metadata: [:])
        }
        
        let template = responses.randomElement() ?? responses.first!
        let responseText = processTemplate(template, entities: entities)
        
        return QuickResponse(
            text: responseText,
            confidence: 0.9,
            metadata: [
                "intent": intent.rawValue,
                "processed_locally": true
            ]
        )
    }
    
    private func processTemplate(_ template: String, entities: [String: Any]) -> String {
        var result = template
        
        if template.contains("{time}") {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            result = result.replacingOccurrences(of: "{time}", with: formatter.string(from: Date()))
        }
        
        // Add more entity replacements as needed
        
        return result
    }
}

// MARK: - Supporting Classes
class NaturalLanguageProcessor {
    func extractEntities(from text: String, for intent: Intent) async -> [String: Any] {
        // Implementation would use NaturalLanguage framework
        // For now, return empty dictionary
        return [:]
    }
}

class LocationManager {
    func getCurrentLocation() async -> LocationInfo? {
        // Implementation would use Core Location
        return nil
    }
}

class CalendarManager {
    func getUpcomingEvents(hours: Int) async -> [CalendarEvent] {
        // Implementation would use EventKit
        return []
    }
}

class DeviceInfoProvider {
    func getDeviceInfo() async -> DeviceInfo {
        return DeviceInfo(
            model: UIDevice.current.model,
            systemVersion: UIDevice.current.systemVersion,
            batteryLevel: UIDevice.current.batteryLevel,
            isCharging: UIDevice.current.batteryState == .charging
        )
    }
}

// MARK: - Data Models
struct UserContext {
    let location: LocationInfo?
    let upcomingEvents: [CalendarEvent]
    let deviceInfo: DeviceInfo
    let environmentInfo: EnvironmentInfo
    let timestamp: Date
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "timestamp": timestamp.timeIntervalSince1970,
            "device": deviceInfo.toDictionary(),
            "environment": environmentInfo.toDictionary()
        ]
        
        if let location = location {
            dict["location"] = location.toDictionary()
        }
        
        if !upcomingEvents.isEmpty {
            dict["upcoming_events"] = upcomingEvents.map { $0.toDictionary() }
        }
        
        return dict
    }
}

struct LocationInfo {
    let latitude: Double
    let longitude: Double
    let city: String?
    let country: String?
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "latitude": latitude,
            "longitude": longitude
        ]
        
        if let city = city {
            dict["city"] = city
        }
        
        if let country = country {
            dict["country"] = country
        }
        
        return dict
    }
}

struct CalendarEvent {
    let title: String
    let startDate: Date
    let endDate: Date
    let location: String?
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "title": title,
            "start_date": startDate.timeIntervalSince1970,
            "end_date": endDate.timeIntervalSince1970
        ]
        
        if let location = location {
            dict["location"] = location
        }
        
        return dict
    }
}

struct DeviceInfo {
    let model: String
    let systemVersion: String
    let batteryLevel: Float
    let isCharging: Bool
    
    func toDictionary() -> [String: Any] {
        return [
            "model": model,
            "system_version": systemVersion,
            "battery_level": batteryLevel,
            "is_charging": isCharging
        ]
    }
}

struct EnvironmentInfo {
    let timeOfDay: TimeOfDay
    let batteryLevel: Float
    let networkType: NetworkType
    let isLowPowerModeEnabled: Bool
    
    func toDictionary() -> [String: Any] {
        return [
            "time_of_day": timeOfDay.rawValue,
            "battery_level": batteryLevel,
            "network_type": networkType.rawValue,
            "low_power_mode": isLowPowerModeEnabled
        ]
    }
}

struct AIResponse {
    let text: String
    let confidence: Double
    let isLocal: Bool
    let metadata: [String: Any]
}

struct AudioData {
    let data: Data
    let format: AudioFormat
    let duration: TimeInterval
    let text: String
}

struct AudioChunk {
    let data: Data
    let index: Int
    let isLast: Bool
}

struct SynthesisOptions: Hashable {
    let shouldCache: Bool
    let priority: Priority
    let quality: Quality
    
    static let `default` = SynthesisOptions(
        shouldCache: true,
        priority: .normal,
        quality: .high
    )
    
    enum Priority {
        case low, normal, high
    }
    
    enum Quality {
        case low, medium, high
    }
}

struct LocalCommandResult {
    let text: String
    let confidence: Double
    let metadata: [String: Any]
    let intent: Intent
    let entities: [String: Any]
}

struct QuickResponse {
    let text: String
    let confidence: Double
    let metadata: [String: Any]
}

// MARK: - Enums
enum Intent: String, CaseIterable {
    case greeting
    case time
    case weather
    case reminder
    case timer
    case music
    case question
    case farewell
    case unknown
}

enum TimeOfDay: String {
    case morning, afternoon, evening, night
    
    static var current: TimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return .morning
        case 12..<17: return .afternoon
        case 17..<22: return .evening
        default: return .night
        }
    }
}

enum NetworkType: String {
    case wifi, cellular, none
}

enum AudioFormat {
    case mpeg, wav, aac
}

enum ExportFormat {
    case json, text, markdown
}

enum ProcessingError: Error {
    case invalidResponse
    case processingFailed
    case contextUnavailable
}

enum ConversationError: Error {
    case noActiveSession
    case sessionNotFound
    case saveFailed
}

// MARK: - Extensions
extension DateFormatter {
    static let shared: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let timeOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Cache Manager
class AudioCacheManager {
    private let cache = NSCache<NSString, AudioData>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    init() {
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = urls[0].appendingPathComponent("AudioCache")
        
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Configure cache limits
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
    
    func getCachedAudio(for key: String) async -> AudioData? {
        // Check memory cache first
        if let audioData = cache.object(forKey: key as NSString) {
            return audioData
        }
        
        // Check disk cache
        let fileURL = cacheDirectory.appendingPathComponent("\(key).audio")
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let audioData = try JSONDecoder().decode(CachedAudioData.self, from: data)
            
            let result = AudioData(
                data: audioData.audioData,
                format: audioData.format,
                duration: audioData.duration,
                text: audioData.text
            )
            
            // Store in memory cache
            cache.setObject(result, forKey: key as NSString)
            
            return result
        } catch {
            return nil
        }
    }
    
    func cacheAudio(_ audioData: AudioData, for key: String) async {
        // Store in memory cache
        cache.setObject(audioData, forKey: key as NSString)
        
        // Store in disk cache
        let cachedData = CachedAudioData(
            audioData: audioData.data,
            format: audioData.format,
            duration: audioData.duration,
            text: audioData.text
        )
        
        do {
            let data = try JSONEncoder().encode(cachedData)
            let fileURL = cacheDirectory.appendingPathComponent("\(key).audio")
            try data.write(to: fileURL)
        } catch {
            print("Failed to cache audio: \(error)")
        }
    }
}

struct CachedAudioData: Codable {
    let audioData: Data
    let format: AudioFormat
    let duration: TimeInterval
    let text: String
}