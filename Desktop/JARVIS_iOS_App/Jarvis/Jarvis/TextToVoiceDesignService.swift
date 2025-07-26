//
//  TextToVoiceDesignService.swift
//  Jarvis
//
//  Created by Quinn May on 7/25/25.
//

import Foundation
import AVFoundation
import Combine

class TextToVoiceDesignService: ObservableObject {
    private let baseURL = "https://api.elevenlabs.io/v1"
    private let apiKey: String
    
    @Published var isProcessing = false
    @Published var error: String?
    @Published var availableVoices: [VoiceDesign] = []
    @Published var currentVoice: VoiceDesign?
    @Published var voiceCategories: [VoiceCategory] = []
    
    init(apiKey: String = JARVISConfiguration.elevenLabsAPIKey) {
        self.apiKey = apiKey
        print("🎨 TextToVoiceDesignService initialized")
        // Load data asynchronously
        Task {
            await loadVoiceCategories()
            await loadAvailableVoices()
        }
    }
    
    // MARK: - Voice Design Creation
    
    func createVoiceDesign(name: String, description: String, category: String, imageURL: String? = nil) async throws -> VoiceDesign {
        print("🎨 Creating voice design: \(name)")
        
        await MainActor.run {
            isProcessing = true
            error = nil
        }
        
        let url = URL(string: "\(baseURL)/voice-design")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "xi-api-key")
        
        let requestBody = VoiceDesignRequest(
            name: name,
            description: description,
            category: category,
            image_url: imageURL
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            await MainActor.run {
                isProcessing = false
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ElevenLabsError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                let voiceDesign = try JSONDecoder().decode(VoiceDesign.self, from: data)
                print("✅ Voice design created: \(voiceDesign.name)")
                return voiceDesign
            } else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ Voice design creation failed: \(errorMessage)")
                await MainActor.run {
                    error = "Voice design creation failed: \(errorMessage)"
                }
                throw ElevenLabsError.apiError(errorMessage)
            }
        } catch {
            await MainActor.run {
                isProcessing = false
                self.error = error.localizedDescription
            }
            throw error
        }
    }
    
    // MARK: - Voice Cloning
    
    func cloneVoice(voiceID: String, name: String, description: String, category: String, imageURL: String? = nil) async throws -> VoiceDesign {
        print("🎨 Cloning voice: \(name)")
        
        await MainActor.run {
            isProcessing = true
            error = nil
        }
        
        let url = URL(string: "\(baseURL)/voice-design/\(voiceID)/clone")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "xi-api-key")
        
        let requestBody = VoiceCloneRequest(
            name: name,
            description: description,
            category: category,
            image_url: imageURL
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            await MainActor.run {
                isProcessing = false
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ElevenLabsError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                let voiceDesign = try JSONDecoder().decode(VoiceDesign.self, from: data)
                print("✅ Voice cloned: \(voiceDesign.name)")
                return voiceDesign
            } else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ Voice cloning failed: \(errorMessage)")
                await MainActor.run {
                    error = "Voice cloning failed: \(errorMessage)"
                }
                throw ElevenLabsError.apiError(errorMessage)
            }
        } catch {
            await MainActor.run {
                isProcessing = false
                self.error = error.localizedDescription
            }
            throw error
        }
    }
    
    // MARK: - Voice Management
    
    func updateVoiceDesign(voiceID: String, name: String? = nil, description: String? = nil, category: String? = nil, imageURL: String? = nil) async throws -> VoiceDesign {
        print("🎨 Updating voice design: \(voiceID)")
        
        await MainActor.run {
            isProcessing = true
            error = nil
        }
        
        let url = URL(string: "\(baseURL)/voice-design/\(voiceID)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "xi-api-key")
        
        var updateData: [String: Any] = [:]
        if let name = name { updateData["name"] = name }
        if let description = description { updateData["description"] = description }
        if let category = category { updateData["category"] = category }
        if let imageURL = imageURL { updateData["image_url"] = imageURL }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: updateData)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            await MainActor.run {
                isProcessing = false
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ElevenLabsError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                let voiceDesign = try JSONDecoder().decode(VoiceDesign.self, from: data)
                print("✅ Voice design updated: \(voiceDesign.name)")
                return voiceDesign
            } else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ Voice design update failed: \(errorMessage)")
                await MainActor.run {
                    error = "Voice design update failed: \(errorMessage)"
                }
                throw ElevenLabsError.apiError(errorMessage)
            }
        } catch {
            await MainActor.run {
                isProcessing = false
                self.error = error.localizedDescription
            }
            throw error
        }
    }
    
    func deleteVoiceDesign(voiceID: String) async throws {
        print("🎨 Deleting voice design: \(voiceID)")
        
        await MainActor.run {
            isProcessing = true
            error = nil
        }
        
        let url = URL(string: "\(baseURL)/voice-design/\(voiceID)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "xi-api-key")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            await MainActor.run {
                isProcessing = false
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ElevenLabsError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                print("✅ Voice design deleted: \(voiceID)")
                // Refresh available voices
                await loadAvailableVoices()
            } else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ Voice design deletion failed: \(errorMessage)")
                await MainActor.run {
                    error = "Voice design deletion failed: \(errorMessage)"
                }
                throw ElevenLabsError.apiError(errorMessage)
            }
        } catch {
            await MainActor.run {
                isProcessing = false
                self.error = error.localizedDescription
            }
            throw error
        }
    }
    
    // MARK: - Voice Loading
    
    private func loadAvailableVoices() async {
        do {
            let url = URL(string: "\(baseURL)/voice-design")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "xi-api-key")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw ElevenLabsError.invalidResponse
            }
            
            let voicesResponse = try JSONDecoder().decode(VoiceDesignsResponse.self, from: data)
            await MainActor.run {
                self.availableVoices = voicesResponse.voices
                if let defaultVoice = voicesResponse.voices.first {
                    self.currentVoice = defaultVoice
                }
            }
            print("✅ Loaded \(voicesResponse.voices.count) voice designs")
        } catch {
            print("❌ Failed to load voice designs: \(error)")
            await MainActor.run {
                self.error = "Failed to load voice designs: \(error.localizedDescription)"
            }
        }
    }
    
    private func loadVoiceCategories() async {
        do {
            let url = URL(string: "\(baseURL)/voice-design/categories")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "xi-api-key")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw ElevenLabsError.invalidResponse
            }
            
            let categoriesResponse = try JSONDecoder().decode(VoiceCategoriesResponse.self, from: data)
            await MainActor.run {
                self.voiceCategories = categoriesResponse.categories
            }
            print("✅ Loaded \(categoriesResponse.categories.count) voice categories")
        } catch {
            print("❌ Failed to load voice categories: \(error)")
        }
    }
    
    // MARK: - Voice Selection
    
    func selectVoice(_ voice: VoiceDesign) {
        currentVoice = voice
        print("🎨 Selected voice: \(voice.name)")
    }
    
    func getVoiceByID(_ voiceID: String) -> VoiceDesign? {
        return availableVoices.first { $0.voice_id == voiceID }
    }
    
    func getVoicesByCategory(_ category: String) -> [VoiceDesign] {
        return availableVoices.filter { $0.category == category }
    }
    
    func searchVoices(query: String) -> [VoiceDesign] {
        let lowercasedQuery = query.lowercased()
        return availableVoices.filter { voice in
            voice.name.lowercased().contains(lowercasedQuery) ||
            voice.description.lowercased().contains(lowercasedQuery) ||
            voice.category.lowercased().contains(lowercasedQuery)
        }
    }
}

// MARK: - Data Models

struct VoiceDesign: Codable, Identifiable {
    let voice_id: String
    let name: String
    let description: String
    let category: String
    let image_url: String?
    let created_at: String
    let updated_at: String
    let is_public: Bool
    let is_verified: Bool
    let is_cloned: Bool
    let original_voice_id: String?
    let owner_id: String?
    let usage_count: Int
    let rating: Double?
    let tags: [String]
    
    var id: String { voice_id }
    
    var formattedCreatedDate: String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: created_at) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        }
        return created_at
    }
    
    var isProfessional: Bool {
        return category == JARVISConfiguration.ElevenLabs.VoiceCategories.professional
    }
    
    var isMultilingual: Bool {
        return category == JARVISConfiguration.ElevenLabs.VoiceCategories.multilingual
    }
}

struct VoiceCategory: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let voice_count: Int
    let is_public: Bool
    
    var displayName: String {
        return name.capitalized
    }
}

struct VoiceDesignRequest: Codable {
    let name: String
    let description: String
    let category: String
    let image_url: String?
}

struct VoiceCloneRequest: Codable {
    let name: String
    let description: String
    let category: String
    let image_url: String?
}

struct VoiceDesignsResponse: Codable {
    let voices: [VoiceDesign]
    let total_count: Int
    let page: Int
    let page_size: Int
}

struct VoiceCategoriesResponse: Codable {
    let categories: [VoiceCategory]
    let total_count: Int
}

// MARK: - Voice Design Extensions

extension VoiceDesign {
    var categoryDisplayName: String {
        switch category {
        case JARVISConfiguration.ElevenLabs.VoiceCategories.professional:
            return "Professional"
        case JARVISConfiguration.ElevenLabs.VoiceCategories.casual:
            return "Casual"
        case JARVISConfiguration.ElevenLabs.VoiceCategories.character:
            return "Character"
        case JARVISConfiguration.ElevenLabs.VoiceCategories.multilingual:
            return "Multilingual"
        default:
            return category.capitalized
        }
    }
    
    var categoryColor: String {
        switch category {
        case JARVISConfiguration.ElevenLabs.VoiceCategories.professional:
            return JARVISConfiguration.App.UI.primaryColor
        case JARVISConfiguration.ElevenLabs.VoiceCategories.casual:
            return JARVISConfiguration.App.UI.accentColor
        case JARVISConfiguration.ElevenLabs.VoiceCategories.character:
            return JARVISConfiguration.App.UI.secondaryColor
        case JARVISConfiguration.ElevenLabs.VoiceCategories.multilingual:
            return "FFD700" // Gold
        default:
            return JARVISConfiguration.App.UI.textColor
        }
    }
    
    var isVerifiedBadge: String {
        return is_verified ? "✓" : ""
    }
    
    var isPublicBadge: String {
        return is_public ? "🌐" : "🔒"
    }
    
    var usageDisplay: String {
        if usage_count > 1000 {
            return "\(usage_count / 1000)k uses"
        } else {
            return "\(usage_count) uses"
        }
    }
    
    var ratingDisplay: String {
        if let rating = rating {
            return String(format: "%.1f", rating)
        }
        return "N/A"
    }
} 