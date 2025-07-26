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
        print("🎙️ ElevenLabsService initialized with API key: \(String(apiKey.prefix(10)))...")
    }
    
    func synthesizeSpeech(text: String, voiceID: String = JARVISConfiguration.ElevenLabs.defaultVoiceID) async throws -> Data {
        print("🎙️ Starting speech synthesis for: \(text)")
        
        guard apiKey != "YOUR_ELEVENLABS_API_KEY_HERE" else {
            print("❌ Invalid API key detected")
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
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
            print("🎙️ Request body encoded successfully")
        } catch {
            print("❌ Failed to encode request body: \(error)")
            throw ElevenLabsError.invalidRequest
        }
        
        print("🎙️ Sending request to ElevenLabs API...")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw ElevenLabsError.invalidResponse
        }
        
        print("🎙️ Received response with status code: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ API Error (\(httpResponse.statusCode)): \(errorMessage)")
            await MainActor.run {
                error = "API Error (\(httpResponse.statusCode)): \(errorMessage)"
            }
            throw ElevenLabsError.apiError(httpResponse.statusCode, errorMessage)
        }
        
        print("✅ Speech synthesis successful, received \(data.count) bytes")
        return data
    }
    
    func playAudio(_ audioData: Data) async throws {
        print("🔊 Playing audio...")
        
        do {
            // Stop any currently playing audio
            stopAudio()
            
            // Create audio player
            audioPlayer = try AVAudioPlayer(data: audioData)
            audioPlayer?.delegate = AudioPlayerDelegate.shared
            audioPlayer?.prepareToPlay()
            
            // Configure audio session for playback
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
            
            // Start playback
            let success = audioPlayer?.play() ?? false
            if success {
                print("✅ Audio playback started")
            } else {
                print("❌ Failed to start audio playback")
                throw ElevenLabsError.playbackError(NSError(domain: "AudioPlayback", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to start playback"]))
            }
        } catch {
            print("❌ Audio playback error: \(error)")
            throw ElevenLabsError.playbackError(error)
        }
    }
    
    func stopAudio() {
        print("🔇 Stopping audio...")
        audioPlayer?.stop()
        audioPlayer = nil
    }
}

// MARK: - Audio Player Delegate
class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    static let shared = AudioPlayerDelegate()
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("🔊 Audio playback finished successfully: \(flag)")
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("❌ Audio decode error: \(error?.localizedDescription ?? "Unknown error")")
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
    case invalidRequest
    case invalidResponse
    case apiError(Int, String)
    case playbackError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Please configure your ElevenLabs API key in Configuration.swift"
        case .invalidRequest:
            return "Invalid request to ElevenLabs API"
        case .invalidResponse:
            return "Invalid response from ElevenLabs API"
        case .apiError(let code, let message):
            return "API Error (\(code)): \(message)"
        case .playbackError(let error):
            return "Audio playback error: \(error.localizedDescription)"
        }
    }
} 