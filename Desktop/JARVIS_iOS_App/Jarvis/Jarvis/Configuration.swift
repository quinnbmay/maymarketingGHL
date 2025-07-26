//
//  Configuration.swift
//  Jarvis
//
//  Created by Quinn May on 7/25/25.
//

import Foundation

struct JARVISConfiguration {
    // MARK: - API Keys
    // ⚠️ IMPORTANT: Replace these with your actual API keys
    // For production: Store in iOS Keychain or environment variables
    
    static let elevenLabsAPIKey = "sk_f9bf84125ea4a0dcbbe4adcf9e655439a9c08ea8fef16ab6"
    
    // MARK: - ElevenLabs Configuration
    struct ElevenLabs {
        static let baseURL = "https://api.elevenlabs.io/v1"
        static let defaultVoiceID = "pNInz6obpgDQGcFmaJgB" // Adam voice
        
        // Voice settings
        static let defaultStability = 0.75
        static let defaultSimilarityBoost = 0.75
        static let defaultStyle = 0.0
        static let defaultSpeakerBoost = true
        
        // WebSocket settings
        static let defaultInactivityTimeout = 20
        static let defaultSyncAlignment = false
        static let defaultAutoMode = false
        static let defaultApplyTextNormalization = "auto"
        static let defaultEnableLogging = true
        static let defaultEnableSSMLParsing = false
        
        // Text-to-Voice Design settings
        static let defaultModelID = "eleven_multilingual_ttv_v2"
        static let defaultLoudness = 0.5
        static let defaultGuidanceScale = 5.0
        static let defaultQuality = 0.5
        static let defaultPromptStrength = 0.5
        
        // Multi-Context WebSocket settings
        struct MultiContext {
            static let maxContexts = 10
            static let defaultContextTimeout = 180
            static let enableContextManagement = true
        }
        
        // Language Models for Conversational AI
        struct LanguageModels {
            static let gpt4o = "gpt-4o"
            static let gpt4oMini = "gpt-4o-mini"
            static let claude3Opus = "claude-3-opus-20240229"
            static let claude3Sonnet = "claude-3-sonnet-20240229"
            static let claude3Haiku = "claude-3-haiku-20240307"
        }
        
        // Conversational AI Configuration
        struct ConversationalAI {
            static let enabled = true
            static let agentID = "" // Set your agent ID here
            static let defaultLanguageModel = LanguageModels.gpt4o
            static let enableKnowledgeBase = true
            static let enableTools = true
            static let enableDynamicVariables = true
        }
        
        // Voice Categories
        struct VoiceCategories {
            static let professional = "professional"
            static let casual = "casual"
            static let character = "character"
            static let multilingual = "multilingual"
        }
        
        // Output Formats
        struct OutputFormats {
            static let mp3 = "mp3"
            static let wav = "wav"
            static let flac = "flac"
            static let aac = "aac"
            static let ogg = "ogg"
        }
        
        // Model IDs
        struct ModelIDs {
            static let elevenMonolingualV1 = "eleven_monolingual_v1"
            static let elevenMultilingualV1 = "eleven_multilingual_v1"
            static let elevenTurboV2 = "eleven_turbo_v2"
            static let elevenTurboV2_5 = "eleven_turbo_v2_5"
            static let elevenFlashV2_5 = "eleven_flash_v2_5"
            static let elevenV3 = "eleven_v3"
        }
        
        // Speech-to-Text Models
        struct STTModels {
            static let elevenEnglishSTS = "eleven_english_sts_v2"
            static let elevenMultilingualSTS = "eleven_multilingual_sts_v2"
        }
    }
    
    // MARK: - App Configuration
    struct App {
        static let name = "JARVIS"
        static let version = "2.0.0"
        static let buildNumber = "1"
        
        // UI Configuration
        struct UI {
            static let primaryColor = "00D4FF"
            static let secondaryColor = "FF6B35"
            static let accentColor = "4ECDC4"
            static let backgroundColor = "000000"
            static let textColor = "FFFFFF"
            
            // Animation settings
            static let animationDuration = 0.3
            static let pulseAnimationDuration = 1.0
            static let particleAnimationDuration = 2.0
        }
        
        // Audio Configuration
        struct Audio {
            static let sampleRate = 44100
            static let bitDepth = 16
            static let channels = 1
            static let bufferSize = 1024
            static let enableEchoCancellation = true
            static let enableNoiseSuppression = true
        }
        
        // Speech Recognition Configuration
        struct SpeechRecognition {
            static let language = "en-US"
            static let enableContinuousRecognition = true
            static let enablePartialResults = true
            static let maxAlternatives = 1
            static let enableProfanityFilter = false
        }
        
        // Performance Configuration
        struct Performance {
            static let enableCaching = true
            static let maxCacheSize = 100 * 1024 * 1024 // 100MB
            static let enableBackgroundProcessing = true
            static let enableConcurrentProcessing = true
            static let maxConcurrentRequests = 3
        }
        
        // Privacy Configuration
        struct Privacy {
            static let enableLocalProcessing = true
            static let enableDataCollection = false
            static let enableAnalytics = false
            static let enableCrashReporting = false
            static let enableTelemetry = false
        }
    }
    
    // MARK: - Feature Flags
    struct Features {
        static let enableAdvancedVoiceSynthesis = true
        static let enableMultiCharacterDialogue = true
        static let enableRealTimeStreaming = true
        static let enableSpeechToText = true
        static let enableConversationalAI = true
        static let enableVoiceCloning = false
        static let enableFineTuning = false
        static let enableProfessionalVoices = true
        static let enableInstantVoiceCloning = false
    }
    
    // MARK: - Development Configuration
    struct Development {
        static let enableDebugLogging = true
        static let enablePerformanceMonitoring = true
        static let enableNetworkLogging = false
        static let enableMockData = false
        static let enableTestMode = false
    }
    
    // MARK: - Error Messages
    struct ErrorMessages {
        static let networkError = "Network connection error. Please check your internet connection."
        static let apiError = "API service error. Please try again later."
        static let permissionError = "Microphone permission required. Please enable in Settings."
        static let speechRecognitionError = "Speech recognition error. Please try again."
        static let voiceSynthesisError = "Voice synthesis error. Please try again."
        static let authorizationError = "Authorization error. Please check your API key."
        static let unknownError = "An unknown error occurred. Please try again."
    }
    
    // MARK: - Localization
    struct Localization {
        static let defaultLanguage = "en"
        static let supportedLanguages = ["en", "es", "fr", "de", "it", "pt", "ja", "ko", "zh"]
        
        struct Strings {
            static let appName = "JARVIS"
            static let tapToSpeak = "Tap to speak"
            static let listening = "Listening..."
            static let processing = "Processing..."
            static let speaking = "Speaking..."
            static let error = "Error"
            static let success = "Success"
            static let cancel = "Cancel"
            static let retry = "Retry"
            static let settings = "Settings"
            static let help = "Help"
            static let about = "About"
        }
    }
    
    // MARK: - Analytics Configuration
    struct Analytics {
        static let enableUsageTracking = false
        static let enableErrorTracking = false
        static let enablePerformanceTracking = false
        static let enableUserBehaviorTracking = false
    }
    
    // MARK: - Security Configuration
    struct Security {
        static let enableKeychainStorage = true
        static let enableCertificatePinning = false
        static let enableAppTransportSecurity = true
        static let enableSecureRandom = true
    }
}

// MARK: - Environment Configuration
enum AppEnvironment {
    case development
    case staging
    case production
    
    static var current: AppEnvironment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }
    
    var baseURL: String {
        switch self {
        case .development:
            return "https://api.elevenlabs.io/v1"
        case .staging:
            return "https://api.elevenlabs.io/v1"
        case .production:
            return "https://api.elevenlabs.io/v1"
        }
    }
    
    var enableLogging: Bool {
        switch self {
        case .development:
            return true
        case .staging:
            return true
        case .production:
            return false
        }
    }
} 