// MARK: - MCP Message Handler
// This file handles all MCP protocol message processing

import Foundation
import Combine

// MARK: - Message Handler Protocol

protocol MCPMessageHandlerProtocol {
    func processIncomingMessage(_ data: Data) async throws -> MCPMessage
    func prepareOutgoingMessage(_ message: MCPMessage) async throws -> Data
    func handleNotification(_ notification: JSONRPCNotification) async
    func correlateResponse(_ response: JSONRPCResponse) async throws
}

// MARK: - Message Handler Implementation

class MCPMessageHandler: MCPMessageHandlerProtocol {
    private var pendingRequests: [String: CheckedContinuation<JSONRPCResponse, Error>] = [:]
    private var requestTimeouts: [String: Task<Void, Never>] = [:]
    private let timeoutDuration: TimeInterval = 30.0
    private let queue = DispatchQueue(label: "mcp.message.handler", qos: .userInitiated)
    
    // MARK: - Message Processing
    
    func processIncomingMessage(_ data: Data) async throws -> MCPMessage {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // Try to decode as response first
        if let response = try? decoder.decode(JSONRPCResponse.self, from: data) {
            try await correlateResponse(response)
            return MCPMessage(
                id: response.id,
                timestamp: Date(),
                type: .response,
                payload: AnyCodable(response)
            )
        }
        
        // Try to decode as notification
        if let notification = try? decoder.decode(JSONRPCNotification.self, from: data) {
            await handleNotification(notification)
            return MCPMessage(
                id: UUID().uuidString,
                timestamp: Date(),
                type: .notification,
                payload: AnyCodable(notification)
            )
        }
        
        // Try to decode as request
        if let request = try? decoder.decode(JSONRPCRequest.self, from: data) {
            return MCPMessage(
                id: request.id,
                timestamp: Date(),
                type: .request,
                payload: AnyCodable(request)
            )
        }
        
        throw MCPError.invalidResponse("Unable to parse incoming message")
    }
    
    func prepareOutgoingMessage(_ message: MCPMessage) async throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        switch message.type {
        case .request:
            guard let request = message.payload.value as? JSONRPCRequest else {
                throw MCPError.invalidData
            }
            return try encoder.encode(request)
        case .response:
            guard let response = message.payload.value as? JSONRPCResponse else {
                throw MCPError.invalidData
            }
            return try encoder.encode(response)
        case .notification:
            guard let notification = message.payload.value as? JSONRPCNotification else {
                throw MCPError.invalidData
            }
            return try encoder.encode(notification)
        case .error:
            guard let error = message.payload.value as? JSONRPCError else {
                throw MCPError.invalidData
            }
            return try encoder.encode(error)
        }
    }
    
    // MARK: - Request/Response Correlation
    
    func sendRequest(_ request: JSONRPCRequest) async throws -> JSONRPCResponse {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: MCPError.notConnected)
                    return
                }
                
                // Store the continuation for correlation
                self.pendingRequests[request.id] = continuation
                
                // Set up timeout
                let timeoutTask = Task { [weak self] in
                    try? await Task.sleep(nanoseconds: UInt64(self?.timeoutDuration ?? 30.0 * 1_000_000_000))
                    
                    await MainActor.run { [weak self] in
                        if let continuation = self?.pendingRequests.removeValue(forKey: request.id) {
                            continuation.resume(throwing: MCPError.timeout)
                        }
                        self?.requestTimeouts.removeValue(forKey: request.id)
                    }
                }
                
                self.requestTimeouts[request.id] = timeoutTask
            }
        }
    }
    
    func correlateResponse(_ response: JSONRPCResponse) async throws {
        await MainActor.run { [weak self] in
            guard let continuation = self?.pendingRequests.removeValue(forKey: response.id) else {
                return
            }
            
            // Cancel timeout
            self?.requestTimeouts.removeValue(forKey: response.id)?.cancel()
            
            // Resume the continuation
            if let error = response.error {
                continuation.resume(throwing: MCPError.protocolError(error.message))
            } else {
                continuation.resume(returning: response)
            }
        }
    }
    
    // MARK: - Notification Handling
    
    func handleNotification(_ notification: JSONRPCNotification) async {
        switch notification.method {
        case "notifications/tools/list_changed":
            await postNotification(.mcpToolsUpdated, userInfo: [
                MCPNotificationKeys.tools: notification.params?.value ?? [:]
            ])
            
        case "notifications/resources/list_changed":
            await postNotification(.mcpResourcesUpdated, userInfo: [
                MCPNotificationKeys.resources: notification.params?.value ?? [:]
            ])
            
        case "notifications/prompts/list_changed":
            await postNotification(.mcpPromptsUpdated, userInfo: [
                MCPNotificationKeys.prompts: notification.params?.value ?? [:]
            ])
            
        case "notifications/progress":
            await handleProgressNotification(notification)
            
        case "notifications/message":
            await handleMessageNotification(notification)
            
        default:
            print("Unhandled notification method: \(notification.method)")
        }
    }
    
    // MARK: - Specific Notification Handlers
    
    private func handleProgressNotification(_ notification: JSONRPCNotification) async {
        guard let params = notification.params?.value as? [String: Any],
              let progressToken = params["progressToken"] as? String else {
            return
        }
        
        let progress = params["progress"] as? Double ?? 0.0
        let total = params["total"] as? Double
        
        await MainActor.run {
            NotificationCenter.default.post(
                name: Notification.Name("mcpProgress"),
                object: nil,
                userInfo: [
                    "progressToken": progressToken,
                    "progress": progress,
                    "total": total as Any
                ]
            )
        }
    }
    
    private func handleMessageNotification(_ notification: JSONRPCNotification) async {
        guard let params = notification.params?.value as? [String: Any],
              let level = params["level"] as? String,
              let logger = params["logger"] as? String,
              let data = params["data"] else {
            return
        }
        
        await MainActor.run {
            NotificationCenter.default.post(
                name: Notification.Name("mcpMessage"),
                object: nil,
                userInfo: [
                    "level": level,
                    "logger": logger,
                    "data": data
                ]
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func postNotification(_ name: Notification.Name, userInfo: [String: Any]) async {
        await MainActor.run {
            NotificationCenter.default.post(name: name, object: nil, userInfo: userInfo)
        }
    }
}

// MARK: - JSON-RPC Notification

struct JSONRPCNotification: Codable {
    let jsonrpc: String = "2.0"
    let method: String
    let params: AnyCodable?
    
    enum CodingKeys: String, CodingKey {
        case jsonrpc, method, params
    }
}

// MARK: - Message Queue

class MCPMessageQueue {
    private var queue: [MCPMessage] = []
    private let maxQueueSize = 1000
    private let lock = NSLock()
    
    func enqueue(_ message: MCPMessage) {
        lock.lock()
        defer { lock.unlock() }
        
        queue.append(message)
        
        // Maintain queue size
        if queue.count > maxQueueSize {
            queue.removeFirst()
        }
    }
    
    func dequeue() -> MCPMessage? {
        lock.lock()
        defer { lock.unlock() }
        
        return queue.isEmpty ? nil : queue.removeFirst()
    }
    
    func clear() {
        lock.lock()
        defer { lock.unlock() }
        
        queue.removeAll()
    }
    
    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        
        return queue.count
    }
}

// MARK: - Message Validator

class MCPMessageValidator {
    static func validate(_ message: MCPMessage) throws {
        // Validate message ID
        guard !message.id.isEmpty else {
            throw MCPError.invalidData
        }
        
        // Validate timestamp
        guard message.timestamp.timeIntervalSinceNow < 300 else { // 5 minutes tolerance
            throw MCPError.invalidData
        }
        
        // Type-specific validation
        switch message.type {
        case .request:
            try validateRequest(message)
        case .response:
            try validateResponse(message)
        case .notification:
            try validateNotification(message)
        case .error:
            try validateError(message)
        }
    }
    
    private static func validateRequest(_ message: MCPMessage) throws {
        guard let request = message.payload.value as? JSONRPCRequest else {
            throw MCPError.invalidData
        }
        
        guard !request.method.isEmpty else {
            throw MCPError.protocolError("Request method cannot be empty")
        }
    }
    
    private static func validateResponse(_ message: MCPMessage) throws {
        guard let response = message.payload.value as? JSONRPCResponse else {
            throw MCPError.invalidData
        }
        
        // Response must have either result or error, but not both
        guard (response.result != nil) != (response.error != nil) else {
            throw MCPError.protocolError("Response must have either result or error")
        }
    }
    
    private static func validateNotification(_ message: MCPMessage) throws {
        guard let notification = message.payload.value as? JSONRPCNotification else {
            throw MCPError.invalidData
        }
        
        guard !notification.method.isEmpty else {
            throw MCPError.protocolError("Notification method cannot be empty")
        }
    }
    
    private static func validateError(_ message: MCPMessage) throws {
        guard let error = message.payload.value as? JSONRPCError else {
            throw MCPError.invalidData
        }
        
        guard !error.message.isEmpty else {
            throw MCPError.protocolError("Error message cannot be empty")
        }
    }
}