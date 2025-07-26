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
        
        // Conversational AI Settings
        struct ConversationalAI {
            static let enabled = false // Set to true to use Conversational AI
            static let agentID = "" // Your Conversational AI agent ID
            static let useTurnTaking = true
            static let silenceTimeout: TimeInterval = 10.0 // Seconds of silence before cost reduction
            static let audioFormat = "pcm_16k" // Supported: pcm_8k, pcm_16k, pcm_22k, pcm_24k, pcm_44k, mulaw_8k
        }
        
        // Popular Voice Options (from ElevenLabs voice library)
        struct Voices {
            static let adam = "pNInz6obpgDQGcFmaJgB"
            static let bella = "EXAVITQu4vr4xnSDxMaL"
            static let charlie = "VR6AewLTigWG4xSOukaG"
            static let dorothy = "ThT5KcBeYPX3keUQqHPh"
            static let echo = "VR6AewLTigWG4xSOukaG"
            static let fin = "VR6AewLTigWG4xSOukaG"
            static let george = "VR6AewLTigWG4xSOukaG"
            static let jennifer = "VR6AewLTigWG4xSOukaG"
            static let josh = "TxGEqnHWrfWFTfGW9XjX"
            static let liam = "VR6AewLTigWG4xSOukaG"
            static let rachel = "21m00Tcm4TlvDq8ikWAM"
            static let sam = "VR6AewLTigWG4xSOukaG"
            static let serena = "VR6AewLTigWG4xSOukaG"
            static let thomas = "VR6AewLTigWG4xSOukaG"
            static let will = "VR6AewLTigWG4xSOukaG"
        }
        
        // Language Model Options (if using Conversational AI)
        struct LanguageModels {
            static let gemini25Flash = "gemini-2.5-flash"
            static let gemini20Flash = "gemini-2.0-flash"
            static let gpt4o = "gpt-4o"
            static let gpt4oMini = "gpt-4o-mini"
            static let claude35Sonnet = "claude-3-5-sonnet"
            static let claudeSonnet4 = "claude-sonnet-4"
        }
    }
    
    // MARK: - MCP Server Configuration
    struct MCP {
        static let defaultServers = [
            MCPServerConfig(
                name: "n8n Workflow Server",
                url: "wss://your-n8n-instance.com/webhook/mcp",
                authType: .apiKey("your-n8n-api-key")
            )
        ]
    }
    
    // MARK: - App Settings
    struct App {
        static let maxConversationHistory = 100
        static let audioRecordingTimeout: TimeInterval = 30.0
        static let speechRecognitionTimeout: TimeInterval = 5.0
        static let animationDuration: TimeInterval = 0.3
        static let particleCount = 200
        
        // Conversational AI Features
        static let enableMultiVoice = false // For multi-character storytelling
        static let enableKnowledgeBase = false // For custom knowledge integration
        static let enableDynamicVariables = false // For personalized responses
        static let enableServerTools = false // For server-side integrations
        static let enableClientTools = false // For client-side functionality
    }
    
    // MARK: - Audio Configuration
    struct Audio {
        static let sampleRate: Double = 16000
        static let bufferSize: UInt32 = 1024
        static let audioFormat = "wav"
        static let compressionQuality: Float = 0.8
        
        // Conversational AI Audio Settings
        static let conversationalSampleRate: Double = 16000 // For Conversational AI
        static let supportedFormats = ["pcm_8k", "pcm_16k", "pcm_22k", "pcm_24k", "pcm_44k", "mulaw_8k"]
    }
    
    // MARK: - Pricing Information (for reference)
    struct Pricing {
        static let freeTierMinutes = 15
        static let starterTierMinutes = 50
        static let creatorTierMinutes = 250
        static let proTierMinutes = 1100
        static let scaleTierMinutes = 3600
        static let businessTierMinutes = 13750
        
        static let businessPricePerMinute = 0.08
        static let silenceReductionPercentage = 0.05 // 5% cost during silence
    }
}

// MARK: - MCP Server Configuration Model
struct MCPServerConfig {
    let name: String
    let url: String
    let authType: MCPAuthType
    let isEnabled: Bool
    
    init(name: String, url: String, authType: MCPAuthType, isEnabled: Bool = true) {
        self.name = name
        self.url = url
        self.authType = authType
        self.isEnabled = isEnabled
    }
}

enum MCPAuthType {
    case none
    case apiKey(String)
    case oauth(String)
    case bearer(String)
}

// MARK: - Conversational AI Models
struct ConversationalAIAgent {
    let id: String
    let name: String
    let voiceID: String
    let languageModel: String
    let knowledgeBase: [String]
    let tools: [String]
    let isEnabled: Bool
    
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
}

// MARK: - Setup Instructions
/*
 
 🔧 SETUP INSTRUCTIONS:
 
 1. ElevenLabs API Key:
    - Sign up at https://elevenlabs.io
    - Get your API key from the profile page
    - Replace "YOUR_ELEVENLABS_API_KEY_HERE" above
 
 2. Voice Configuration:
    - Browse available voices at https://elevenlabs.io/voice-library
    - Replace defaultVoiceID with your preferred voice
    - Adjust voice settings (stability, similarity_boost) as needed
 
 3. Conversational AI (Optional):
    - Create a Conversational AI agent at https://elevenlabs.io/conversational-ai
    - Set ConversationalAI.enabled = true
    - Add your agent ID to ConversationalAI.agentID
    - Choose your preferred language model
    - Configure knowledge bases and tools as needed
 
 4. MCP Servers:
    - Configure your MCP server endpoints
    - Add authentication credentials
    - Test connection before deployment
 
 5. Security (Production):
    - Move API keys to iOS Keychain
    - Use environment variables for builds
    - Implement certificate pinning
 
 6. Pricing Considerations:
    - Free tier: 15 minutes/month
    - Business tier: $0.08/minute
    - Silence periods: 5% of normal cost
    - Setup & testing: 50% of normal cost
 
 */ 