// JARVIS Configuration - API Keys and Settings

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
    }
    
    // MARK: - Audio Configuration
    struct Audio {
        static let sampleRate: Double = 16000
        static let bufferSize: UInt32 = 1024
        static let audioFormat = "wav"
        static let compressionQuality: Float = 0.8
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
 
 3. MCP Servers:
    - Configure your MCP server endpoints
    - Add authentication credentials
    - Test connection before deployment
 
 4. Security (Production):
    - Move API keys to iOS Keychain
    - Use environment variables for builds
    - Implement certificate pinning
 
 */