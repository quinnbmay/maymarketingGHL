// JARVIS iOS App - Main App Entry Point

import SwiftUI
import AVFoundation

@main
struct JARVISApp: App {
    @StateObject private var dependencies = AppDependencies()
    
    init() {
        setupAppearance()
        configureAudioSession()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dependencies)
                .preferredColorScheme(.dark)
                .onAppear {
                    requestPermissions()
                }
        }
    }
    
    private func setupAppearance() {
        // Configure status bar
        UIApplication.shared.statusBarStyle = .lightContent
        
        // Configure navigation appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 20, weight: .semibold)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Configure tab bar appearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithTransparentBackground()
        tabAppearance.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, 
                                       mode: .voiceChat, 
                                       options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    private func requestPermissions() {
        // Request microphone permission
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                print("Microphone permission granted")
            } else {
                print("Microphone permission denied")
            }
        }
        
        // Request speech recognition permission
        SFSpeechRecognizer.requestAuthorization { status in
            switch status {
            case .authorized:
                print("Speech recognition authorized")
            case .denied, .restricted, .notDetermined:
                print("Speech recognition not authorized")
            @unknown default:
                print("Unknown speech recognition status")
            }
        }
    }
}

// MARK: - ContentView
struct ContentView: View {
    @EnvironmentObject var dependencies: AppDependencies
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            if showOnboarding {
                OnboardingView(showOnboarding: $showOnboarding)
                    .environmentObject(dependencies)
            } else {
                VoiceAssistantView(dependencies: dependencies)
            }
        }
    }
}

// MARK: - App Dependencies
class AppDependencies: ObservableObject {
    lazy var audioEngineService = AudioEngineService()
    lazy var elevenLabsService = ElevenLabsService()
    lazy var mcpBridgeService = MCPBridgeService()
    lazy var secureConfigurationManager = SecureConfigurationManager()
    lazy var biometricAuthManager = BiometricAuthManager()
    
    // Use cases
    lazy var processVoiceCommandUseCase = ProcessVoiceCommandUseCase(
        audioService: audioEngineService,
        elevenLabsService: elevenLabsService,
        mcpService: mcpBridgeService
    )
    
    lazy var synthesizeSpeechUseCase = SynthesizeSpeechUseCase(
        elevenLabsService: elevenLabsService,
        audioService: audioEngineService
    )
    
    lazy var manageConversationUseCase = ManageConversationUseCase()
}

import Speech

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppDependencies())
    }
}