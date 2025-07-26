// MARK: - MCP iOS Models
// This file contains all the data models for MCP integration

import Foundation

// MARK: - Configuration Models

struct MCPServerConfig: Codable, Identifiable {
    let id = UUID()
    let name: String
    let description: String?
    let transport: TransportType
    let authMethod: MCPAuthenticationManager.AuthMethod?
    let metadata: [String: String]?
    
    enum TransportType: Codable {
        case webSocket(URL)
        case httpSSE(URL)
        case stdio
        
        enum CodingKeys: String, CodingKey {
            case type, url
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .webSocket(let url):
                try container.encode("websocket", forKey: .type)
                try container.encode(url, forKey: .url)
            case .httpSSE(let url):
                try container.encode("httpsse", forKey: .type)
                try container.encode(url, forKey: .url)
            case .stdio:
                try container.encode("stdio", forKey: .type)
            }
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)
            
            switch type {
            case "websocket":
                let url = try container.decode(URL.self, forKey: .url)
                self = .webSocket(url)
            case "httpsse":
                let url = try container.decode(URL.self, forKey: .url)
                self = .httpSSE(url)
            case "stdio":
                self = .stdio
            default:
                throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown transport type")
            }
        }
    }
}

// MARK: - Credentials

struct MCPCredentials: Codable {
    let type: CredentialType
    let data: [String: String]
    let expiresAt: Date?
    
    enum CredentialType: String, Codable {
        case bearerToken
        case apiKey
        case oauth2
        case custom
    }
}

// MARK: - Server Capabilities

struct MCPServerCapabilities: Codable {
    let protocolVersion: String
    let tools: MCPToolsCapability?
    let resources: MCPResourcesCapability?
    let prompts: MCPPromptsCapability?
    let serverInfo: MCPServerInfo?
}

struct MCPToolsCapability: Codable {
    let listChanged: Bool?
}

struct MCPResourcesCapability: Codable {
    let subscribe: Bool?
    let listChanged: Bool?
}

struct MCPPromptsCapability: Codable {
    let listChanged: Bool?
}

struct MCPServerInfo: Codable {
    let name: String
    let version: String?
}

// MARK: - Operation Results

struct MCPToolResult: Codable {
    let content: [MCPContent]
    let isError: Bool?
}

struct MCPResourceContent: Codable {
    let contents: [MCPContent]
}

struct MCPPromptResult: Codable {
    let description: String?
    let messages: [MCPPromptMessage]
}

struct MCPPromptMessage: Codable {
    let role: MCPRole
    let content: MCPContent
}

enum MCPRole: String, Codable {
    case user
    case assistant
    case system
}

struct MCPContent: Codable {
    let type: MCPContentType
    let text: String?
    let data: String?
    let mimeType: String?
    
    enum MCPContentType: String, Codable {
        case text
        case image
        case resource
    }
}

// MARK: - Message Handler Types

struct MCPMessage: Codable {
    let id: String
    let timestamp: Date
    let type: MCPMessageType
    let payload: AnyCodable
}

// MARK: - AnyCodable Helper

struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}

// MARK: - Notification Types

extension Notification.Name {
    static let mcpServerConnected = Notification.Name("mcpServerConnected")
    static let mcpServerDisconnected = Notification.Name("mcpServerDisconnected")
    static let mcpServerError = Notification.Name("mcpServerError")
    static let mcpToolsUpdated = Notification.Name("mcpToolsUpdated")
    static let mcpResourcesUpdated = Notification.Name("mcpResourcesUpdated")
    static let mcpPromptsUpdated = Notification.Name("mcpPromptsUpdated")
}

// MARK: - User Info Keys

struct MCPNotificationKeys {
    static let serverId = "serverId"
    static let error = "error"
    static let tools = "tools"
    static let resources = "resources"
    static let prompts = "prompts"
}