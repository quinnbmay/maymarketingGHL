//
//  ElevenLabsService.swift
//  Jarvis
//
//  Created by Quinn May on 7/25/25.
//

import Foundation
import AVFoundation
import Combine

class ElevenLabsService: ObservableObject {
    private let baseURL = "https://api.elevenlabs.io/v1"
    private let apiKey: String
    private var audioPlayer: AVAudioPlayer?
    
    @Published var isSynthesizing = false
    @Published var error: String?
    
    init(apiKey: String = JARVISConfiguration.elevenLabsAPIKey) {
        self.apiKey = apiKey
    }
    
    func synthesizeSpeech(text: String, voiceID: String = JARVISConfiguration.ElevenLabs.defaultVoiceID) async throws -> Data {
        guard apiKey != "YOUR_ELEVENLABS_API_KEY_HERE" else {
            throw ElevenLabsError.invalidAPIKey
        }
        
        await MainActor.run {
            isSynthesizing = true
            error = nil
        }
        
        defer {
            Task { @MainActor in
                isSynthesizing = false
            }
        }
        
        let url = URL(string: "\(baseURL)/text-to-speech/\(voiceID)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        
        let requestBody = ElevenLabsRequest(
            text: text,
            model_id: "eleven_monolingual_v1",
            voice_settings: VoiceSettings(
                stability: JARVISConfiguration.ElevenLabs.defaultStability,
                similarity_boost: JARVISConfiguration.ElevenLabs.defaultSimilarityBoost,
                style: JARVISConfiguration.ElevenLabs.defaultStyle,
                use_speaker_boost: JARVISConfiguration.ElevenLabs.defaultSpeakerBoost
            )
        )
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ElevenLabsError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            await MainActor.run {
                error = "API Error (\(httpResponse.statusCode)): \(errorMessage)"
            }
            throw ElevenLabsError.apiError(httpResponse.statusCode, errorMessage)
        }
        
        return data
    }
    
    func playAudio(_ audioData: Data) async throws {
        do {
            audioPlayer = try AVAudioPlayer(data: audioData)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            throw ElevenLabsError.playbackError(error)
        }
    }
    
    func stopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
}

// MARK: - Request Models
struct ElevenLabsRequest: Codable {
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

// MARK: - Error Types
enum ElevenLabsError: Error, LocalizedError {
    case invalidAPIKey
    case invalidResponse
    case apiError(Int, String)
    case playbackError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Please configure your ElevenLabs API key in Configuration.swift"
        case .invalidResponse:
            return "Invalid response from ElevenLabs API"
        case .apiError(let code, let message):
            return "API Error (\(code)): \(message)"
        case .playbackError(let error):
            return "Audio playback error: \(error.localizedDescription)"
        }
    }
} 