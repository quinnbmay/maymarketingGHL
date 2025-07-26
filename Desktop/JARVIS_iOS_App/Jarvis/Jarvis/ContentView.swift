//
//  ContentView.swift
//  Jarvis
//
//  Created by Quinn May on 7/25/25.
//

import SwiftUI
import AVFoundation
import Speech
import Combine

struct ContentView: View {
    @StateObject private var dependencies = AppDependencies()
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    
    var body: some View {
        ZStack {
            // JARVIS Background
            Color.black
                .ignoresSafeArea()
            
            // Animated particles background
            ParticleSystemView()
                .ignoresSafeArea()
            
            if showOnboarding {
                OnboardingView(showOnboarding: $showOnboarding)
                    .environmentObject(dependencies)
            } else {
                JARVISMainView()
                    .environmentObject(dependencies)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            requestPermissions()
        }
    }
    
    private func requestPermissions() {
        // Request microphone permission using iOS 17+ API
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if granted {
                        print("✅ Microphone permission granted")
                    } else {
                        print("❌ Microphone permission denied")
                    }
                }
            }
        } else {
            // Fallback for iOS 16 and earlier
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if granted {
                        print("✅ Microphone permission granted")
                    } else {
                        print("❌ Microphone permission denied")
                    }
                }
            }
        }
        
        // Request speech recognition permission
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("✅ Speech recognition authorized")
                case .denied, .restricted, .notDetermined:
                    print("❌ Speech recognition not authorized")
                @unknown default:
                    print("❓ Unknown speech recognition status")
                }
            }
        }
    }
}

// MARK: - JARVIS Main Interface
struct JARVISMainView: View {
    @EnvironmentObject var dependencies: AppDependencies
    @StateObject private var viewModel = VoiceAssistantViewModel()
    @State private var showSettings = false
    @State private var animationPhase = 0.0
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Navigation
            HStack {
                Text("JARVIS")
                    .font(.system(size: 28, weight: .thin, design: .default))
                    .foregroundColor(.white)
                    .opacity(0.9)
                
                Spacer()
                
                Button(action: { showSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .foregroundColor(Color(hex: "00D4FF"))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            Spacer()
            
            // Main Voice Visualizer
            VStack(spacing: 40) {
                // Voice Visualizer Circle
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(
                            Color(hex: "00D4FF").opacity(viewModel.isListening ? 0.8 : 0.3),
                            lineWidth: 2
                        )
                        .frame(width: 200, height: 200)
                        .scaleEffect(viewModel.isListening ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: viewModel.isListening)
                    
                    // Inner circle with gradient
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: "00D4FF").opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(1.0 + sin(animationPhase) * 0.05)
                        .animation(.easeInOut(duration: 3).repeatForever(autoreverses: false), value: animationPhase)
                    
                    // Center tap area
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 200, height: 200)
                        .contentShape(Circle())
                        .onTapGesture {
                            toggleListening()
                        }
                        .onLongPressGesture {
                            startContinuousListening()
                        }
                }
                
                // Status Text
                Text(viewModel.statusText)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .animation(.easeInOut(duration: 0.3), value: viewModel.statusText)
                
                // Processing indicator
                if viewModel.isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "00D4FF")))
                        .scaleEffect(1.2)
                        .padding(.top, 10)
                }
                
                // Transcribed Text
                if !viewModel.transcribedText.isEmpty {
                    Text(viewModel.transcribedText)
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 20) {
                ActionButton(icon: "clock.arrow.circlepath", action: {})
                ActionButton(icon: "keyboard", action: {})
                ActionButton(icon: "list.bullet.rectangle", action: {})
                ActionButton(icon: "mic.slash", action: { viewModel.stopListening() })
            }
            .padding(.bottom, 60)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(dependencies)
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
            animationPhase = .pi * 2
        }
    }
    
    private func toggleListening() {
        if viewModel.isListening {
            viewModel.stopListening()
        } else {
            viewModel.startListening()
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func startContinuousListening() {
        viewModel.startContinuousListening()
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Voice Assistant ViewModel
class VoiceAssistantViewModel: ObservableObject {
    @Published var isListening = false
    @Published var statusText = "Tap to speak"
    @Published var transcribedText = ""
    @Published var isProcessing = false
    
    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let elevenLabsService = ElevenLabsService()
    
    init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    func startListening() {
        guard !isListening else { return }
        
        // Cancel any existing recognition task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        do {
            // Configure audio session for recording
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            // Create recognition request
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else {
                throw NSError(domain: "SpeechRecognition", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create recognition request"])
            }
            
            recognitionRequest.shouldReportPartialResults = true
            recognitionRequest.requiresOnDeviceRecognition = true // For privacy
            
            // Setup audio engine
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                self?.recognitionRequest?.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            // Start recognition
            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                DispatchQueue.main.async {
                    if let result = result {
                        self?.transcribedText = result.bestTranscription.formattedString
                    }
                    
                    if error != nil || result?.isFinal == true {
                        self?.stopListening()
                    }
                }
            }
            
            isListening = true
            statusText = "Listening..."
            
        } catch {
            print("Failed to start recording: \(error)")
            statusText = "Error starting recording"
        }
    }
    
    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        isListening = false
        statusText = "Processing..."
        
        // Process the transcribed text
        if !transcribedText.isEmpty {
            processVoiceCommand(transcribedText)
        }
        
        // Reset audio session
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("Failed to reset audio session: \(error)")
        }
    }
    
    func startContinuousListening() {
        startListening()
        statusText = "Continuous listening..."
    }
    
    private func processVoiceCommand(_ command: String) {
        Task {
            await MainActor.run {
                isProcessing = true
            }
            
            do {
                // Simple response logic - you can expand this
                let response = generateResponse(to: command)
                
                // Synthesize and play the response
                let audioData = try await elevenLabsService.synthesizeSpeech(text: response)
                try await elevenLabsService.playAudio(audioData)
                
                await MainActor.run {
                    statusText = "Tap to speak"
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    statusText = "Error: \(error.localizedDescription)"
                    isProcessing = false
                }
                print("Error processing voice command: \(error)")
            }
        }
    }
    
    private func generateResponse(to command: String) -> String {
        let lowercased = command.lowercased()
        
        if lowercased.contains("hello") || lowercased.contains("hi") {
            return "Hello! I'm JARVIS, your AI assistant. How can I help you today?"
        } else if lowercased.contains("time") {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "The current time is \(formatter.string(from: Date()))"
        } else if lowercased.contains("weather") {
            return "I'm sorry, I don't have access to weather information yet. This feature is coming soon!"
        } else if lowercased.contains("thank") {
            return "You're welcome! Is there anything else I can help you with?"
        } else if lowercased.contains("bye") || lowercased.contains("goodbye") {
            return "Goodbye! Have a great day!"
        } else {
            return "I heard you say: \(command). I'm still learning, but I'll do my best to help you!"
        }
    }
}

// MARK: - Action Button
struct ActionButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(Color(hex: "00D4FF"))
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Particle System Background
struct ParticleSystemView: View {
    @State private var particles: [Particle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(Color(hex: "00D4FF").opacity(0.3))
                        .frame(width: 2, height: 2)
                        .position(particle.position)
                        .animation(
                            .linear(duration: particle.duration)
                            .repeatForever(autoreverses: false),
                            value: particle.position
                        )
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
            }
        }
    }
    
    private func createParticles(in size: CGSize) {
        particles = (0..<100).map { _ in
            Particle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                ),
                duration: Double.random(in: 4...8)
            )
        }
        
        // Animate particles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            for i in particles.indices {
                withAnimation {
                    particles[i].position = CGPoint(
                        x: CGFloat.random(in: 0...size.width),
                        y: CGFloat.random(in: 0...size.height)
                    )
                }
            }
        }
    }
}

// MARK: - Particle Model
struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let duration: Double
}

// MARK: - Onboarding View
struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @EnvironmentObject var dependencies: AppDependencies
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Text("JARVIS")
                .font(.system(size: 72, weight: .ultraLight))
                .foregroundColor(Color(hex: "00D4FF"))
            
            Text("Your Advanced AI Assistant")
                .font(.title2)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Button(action: completeOnboarding) {
                HStack {
                    Text("Initialize System")
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Image(systemName: "arrow.right")
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "00D4FF"), Color(hex: "0099CC")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
            }
            .buttonStyle(ScaleButtonStyle())
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        withAnimation(.easeInOut(duration: 0.5)) {
            showOnboarding = false
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dependencies: AppDependencies
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("JARVIS Settings")
                    .font(.largeTitle)
                    .foregroundColor(Color(hex: "00D4FF"))
                
                VStack(spacing: 16) {
                    SettingRow(title: "Voice Settings", icon: "speaker.wave.2")
                    SettingRow(title: "MCP Servers", icon: "network")
                    SettingRow(title: "Privacy", icon: "lock.shield")
                    SettingRow(title: "About", icon: "info.circle")
                }
                
                Spacer()
            }
            .padding()
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "00D4FF"))
                }
            }
        }
    }
}

// MARK: - Setting Row
struct SettingRow: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "00D4FF"))
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.5))
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - App Dependencies
class AppDependencies: ObservableObject {
    // Add your services here as needed
    init() {
        print("🚀 JARVIS Dependencies initialized")
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ContentView()
}
