//
//  ContentView.swift
//  Jarvis
//
//  Created by Quinn May on 7/25/25.
//

import SwiftUI
import AVFoundation
import Speech

struct ContentView: View {
    @StateObject private var dependencies = AppDependencies()
    @StateObject private var permissionManager = PermissionManager()
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
                OnboardingView(
                    showOnboarding: $showOnboarding,
                    permissionManager: permissionManager
                )
                .environmentObject(dependencies)
            } else {
                JARVISMainView()
                    .environmentObject(dependencies)
                    .environmentObject(permissionManager)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Permission Manager
class PermissionManager: ObservableObject {
    @Published var microphonePermission: AVAudioSession.RecordPermission = .undetermined
    @Published var speechRecognitionPermission: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    
    func requestMicrophonePermission() {
        microphonePermission = AVAudioSession.sharedInstance().recordPermission
        
        if microphonePermission == .undetermined {
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    self?.microphonePermission = granted ? .granted : .denied
                    print("🎤 Microphone permission: \(granted ? "granted" : "denied")")
                }
            }
        }
    }
    
    func requestSpeechRecognitionPermission() {
        speechRecognitionPermission = SFSpeechRecognizer.authorizationStatus()
        
        if speechRecognitionPermission == .notDetermined {
            SFSpeechRecognizer.requestAuthorization { [weak self] status in
                DispatchQueue.main.async {
                    self?.speechRecognitionPermission = status
                    print("🗣️ Speech recognition permission: \(status)")
                }
            }
        }
    }
    
    var hasRequiredPermissions: Bool {
        return microphonePermission == .granted && speechRecognitionPermission == .authorized
    }
}

// MARK: - JARVIS Main Interface
struct JARVISMainView: View {
    @EnvironmentObject var dependencies: AppDependencies
    @EnvironmentObject var permissionManager: PermissionManager
    @StateObject private var viewModel = VoiceAssistantViewModel()
    @StateObject private var audioVisualizer = AudioVisualizer()
    @State private var showSettings = false
    @State private var showHistory = false
    @State private var animationPhase = 0.0
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Navigation
            HStack {
                Text("JARVIS")
                    .font(.system(size: 28, weight: .thin, design: .default))
                    .foregroundColor(.white)
                    .opacity(0.9)
                    .onTapGesture(count: 2) {
                        // Easter egg: double tap to show system info
                        viewModel.showSystemInfo()
                    }
                
                Spacer()
                
                // Connection status indicator
                Circle()
                    .fill(viewModel.isConnected ? Color(hex: "00FF88") : Color(hex: "FF3366"))
                    .frame(width: 8, height: 8)
                    .opacity(0.8)
                
                Button(action: { showSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .foregroundColor(Color(hex: "00D4FF"))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            // Conversation Context Card
            if !viewModel.conversationHistory.isEmpty {
                ConversationContextCard(
                    conversations: Array(viewModel.conversationHistory.suffix(3))
                )
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .onTapGesture {
                    showHistory = true
                }
            }
            
            Spacer()
            
            // Main Voice Visualizer
            VStack(spacing: 40) {
                // Voice Visualizer Circle
                ZStack {
                    // Permission overlay if needed
                    if !permissionManager.hasRequiredPermissions {
                        Circle()
                            .fill(Color.red.opacity(0.1))
                            .frame(width: 220, height: 220)
                        
                        VStack {
                            Image(systemName: "mic.slash")
                                .font(.system(size: 30))
                                .foregroundColor(.red)
                            Text("Permissions Required")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Listening rings (multiple for effect)
                    if viewModel.isListening {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .stroke(
                                    Color(hex: "00D4FF").opacity(0.3 - Double(index) * 0.1),
                                    lineWidth: 1
                                )
                                .frame(width: 200 + CGFloat(index * 20), height: 200 + CGFloat(index * 20))
                                .scaleEffect(viewModel.isListening ? 1.2 + Double(index) * 0.1 : 1.0)
                                .animation(
                                    .easeInOut(duration: 1.5 + Double(index) * 0.2)
                                    .repeatForever(autoreverses: true),
                                    value: viewModel.isListening
                                )
                        }
                    }
                    
                    // Main outer ring
                    Circle()
                        .stroke(
                            Color(hex: "00D4FF").opacity(viewModel.isListening ? 0.8 : 0.3),
                            lineWidth: 2
                        )
                        .frame(width: 200, height: 200)
                        .scaleEffect(viewModel.isListening ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.isListening)
                    
                    // Audio visualization bars (when speaking)
                    if viewModel.isProcessing || viewModel.isSpeaking {
                        AudioVisualizationView(
                            levels: audioVisualizer.levels,
                            isActive: viewModel.isSpeaking
                        )
                        .frame(width: 160, height: 160)
                    }
                    
                    // Inner circle with gradient
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: "00D4FF").opacity(viewModel.isListening ? 0.4 : 0.2),
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
                    
                    // Processing indicator
                    if viewModel.isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "00D4FF")))
                            .scaleEffect(1.5)
                    }
                    
                    // Center tap area
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 200, height: 200)
                        .contentShape(Circle())
                        .onTapGesture {
                            toggleListening()
                        }
                        .onLongPressGesture(minimumDuration: 0.5) {
                            startContinuousListening()
                        }
                        .disabled(!permissionManager.hasRequiredPermissions)
                }
                
                // Status Text with typing effect
                VStack(spacing: 8) {
                    Text(viewModel.statusText)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .animation(.easeInOut(duration: 0.3), value: viewModel.statusText)
                    
                    // ElevenLabs voice indicator
                    if viewModel.isSpeaking {
                        HStack(spacing: 4) {
                            Image(systemName: "speaker.wave.2")
                                .font(.caption)
                            Text("ElevenLabs Voice")
                                .font(.caption)
                        }
                        .foregroundColor(Color(hex: "00D4FF").opacity(0.7))
                    }
                }
                
                // Transcribed Text with better styling
                if !viewModel.transcribedText.isEmpty {
                    ScrollView {
                        Text(viewModel.transcribedText)
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color(hex: "00D4FF").opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }
                    .frame(maxHeight: 100)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                
                // Response text
                if !viewModel.responseText.isEmpty {
                    ScrollView {
                        Text(viewModel.responseText)
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "00D4FF"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hex: "00D4FF").opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color(hex: "00D4FF").opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                    .frame(maxHeight: 120)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 20) {
                ActionButton(icon: "clock.arrow.circlepath") {
                    showHistory = true
                }
                
                ActionButton(icon: "keyboard") {
                    viewModel.showTextInput()
                }
                
                ActionButton(icon: "list.bullet.rectangle") {
                    viewModel.showCommands()
                }
                
                ActionButton(icon: viewModel.isListening ? "mic.slash.fill" : "mic.fill") {
                    if viewModel.isListening {
                        viewModel.stopListening()
                    } else {
                        toggleListening()
                    }
                }
            }
            .padding(.bottom, 60)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(dependencies)
                .environmentObject(permissionManager)
        }
        .sheet(isPresented: $showHistory) {
            ConversationHistoryView(conversations: viewModel.conversationHistory)
        }
        .onAppear {
            startAnimation()
            viewModel.initialize(permissionManager: permissionManager)
        }
    }
    
    private func startAnimation() {
        withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
            animationPhase = .pi * 2
        }
    }
    
    private func toggleListening() {
        guard permissionManager.hasRequiredPermissions else {
            // Request permissions if not granted
            permissionManager.requestMicrophonePermission()
            permissionManager.requestSpeechRecognitionPermission()
            return
        }
        
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
        guard permissionManager.hasRequiredPermissions else { return }
        
        viewModel.startContinuousListening()
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Enhanced Voice Assistant ViewModel
class VoiceAssistantViewModel: ObservableObject {
    @Published var isListening = false
    @Published var isProcessing = false
    @Published var isSpeaking = false
    @Published var isConnected = false
    @Published var statusText = "Tap to speak"
    @Published var transcribedText = ""
    @Published var responseText = ""
    @Published var conversationHistory: [ConversationItem] = []
    
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    private var permissionManager: PermissionManager?
    
    init() {
        setupAudioSession()
        loadConversationHistory()
    }
    
    func initialize(permissionManager: PermissionManager) {
        self.permissionManager = permissionManager
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        checkConnectivity()
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("❌ Audio session setup failed: \(error)")
        }
    }
    
    func startListening() {
        guard let permissionManager = permissionManager,
              permissionManager.hasRequiredPermissions else {
            statusText = "Permissions required"
            return
        }
        
        // Stop any existing recognition
        stopListening()
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            statusText = "Speech recognition unavailable"
            return
        }
        
        isListening = true
        statusText = "Listening..."
        transcribedText = ""
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else {
            stopListening()
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                if let result = result {
                    self?.transcribedText = result.bestTranscription.formattedString
                    
                    if result.isFinal {
                        self?.processCommand(self?.transcribedText ?? "")
                    }
                }
                
                if error != nil {
                    self?.stopListening()
                }
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        do {
            try audioEngine.start()
        } catch {
            print("❌ Audio engine start failed: \(error)")
            stopListening()
        }
        
        // Auto-stop after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if self.isListening {
                self.stopListening()
            }
        }
    }
    
    func stopListening() {
        isListening = false
        statusText = "Tap to speak"
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
    }
    
    func startContinuousListening() {
        statusText = "Continuous listening..."
        startListening()
        
        // Restart listening every 10 seconds for continuous mode
        DispatchQueue.main.asyncAfter(deadline: .now() + 9) {
            if self.isListening {
                self.startListening()
            }
        }
    }
    
    private func processCommand(_ command: String) {
        guard !command.isEmpty else { return }
        
        isProcessing = true
        statusText = "Processing..."
        
        // Add to conversation history
        let userMessage = ConversationItem(
            id: UUID(),
            text: command,
            isUser: true,
            timestamp: Date()
        )
        conversationHistory.append(userMessage)
        
        // Simulate processing and response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.generateResponse(for: command)
        }
    }
    
    private func generateResponse(for command: String) {
        isProcessing = false
        isSpeaking = true
        statusText = "Speaking..."
        
        // Simple command processing
        let response = processSimpleCommand(command)
        responseText = response
        
        // Add JARVIS response to history
        let jarvisResponse = ConversationItem(
            id: UUID(),
            text: response,
            isUser: false,
            timestamp: Date()
        )
        conversationHistory.append(jarvisResponse)
        
        // Simulate ElevenLabs TTS
        synthesizeSpeech(response)
        
        // Save conversation
        saveConversationHistory()
    }
    
    private func processSimpleCommand(_ command: String) -> String {
        let lowercased = command.lowercased()
        
        if lowercased.contains("hello") || lowercased.contains("hi") {
            return "Hello! I'm JARVIS, your advanced AI assistant. How may I help you today?"
        } else if lowercased.contains("time") {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "The current time is \(formatter.string(from: Date()))."
        } else if lowercased.contains("date") {
            let formatter = DateFormatter()
            formatter.dateStyle = .full
            return "Today is \(formatter.string(from: Date()))."
        } else if lowercased.contains("weather") {
            return "I'm currently unable to access weather data, but I can help you with other tasks."
        } else if lowercased.contains("joke") {
            let jokes = [
                "Why don't scientists trust atoms? Because they make up everything!",
                "I told my wife she was drawing her eyebrows too high. She looked surprised.",
                "Why don't eggs tell jokes? They'd crack each other up!"
            ]
            return jokes.randomElement() ?? "I'm still learning to be funny!"
        } else {
            return "I understand you said: '\(command)'. I'm still learning to process complex commands, but I'm here to help!"
        }
    }
    
    private func synthesizeSpeech(_ text: String) {
        // Simulate ElevenLabs API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isSpeaking = false
            self.statusText = "Tap to speak"
            
            // Clear response text after speaking
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.responseText = ""
            }
        }
        
        // Use system TTS as fallback
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
    }
    
    func showSystemInfo() {
        responseText = "JARVIS System Status:\n• ElevenLabs: Connected\n• MCP Servers: Ready\n• Voice Recognition: Active\n• All systems operational"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.responseText = ""
        }
    }
    
    func showTextInput() {
        statusText = "Text input not yet implemented"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.statusText = "Tap to speak"
        }
    }
    
    func showCommands() {
        responseText = "Available Commands:\n• 'Hello' - Greeting\n• 'What time is it?' - Current time\n• 'Tell me a joke' - Random joke\n• 'What's the weather?' - Weather info\n• Double-tap JARVIS logo for system info"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
            self.responseText = ""
        }
    }
    
    private func checkConnectivity() {
        // Simulate connection check
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isConnected = true
        }
    }
    
    private func loadConversationHistory() {
        // Load from UserDefaults or Core Data
        // For now, add a welcome message
        let welcomeMessage = ConversationItem(
            id: UUID(),
            text: "Welcome back! I'm ready to assist you.",
            isUser: false,
            timestamp: Date()
        )
        conversationHistory.append(welcomeMessage)
    }
    
    private func saveConversationHistory() {
        // Save to UserDefaults or Core Data
        // Implementation here
    }
}

// MARK: - Conversation Item Model
struct ConversationItem: Identifiable {
    let id: UUID
    let text: String
    let isUser: Bool
    let timestamp: Date
}

// MARK: - Audio Visualizer
class AudioVisualizer: ObservableObject {
    @Published var levels: [Float] = Array(repeating: 0.0, count: 64)
    
    init() {
        startMockVisualization()
    }
    
    private func startMockVisualization() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.levels = (0..<64).map { _ in Float.random(in: 0...1) }
        }
    }
}

// MARK: - Audio Visualization View
struct AudioVisualizationView: View {
    let levels: [Float]
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<min(levels.count, 32), id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "00D4FF"),
                                Color(hex: "0099CC")
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 3, height: CGFloat(levels[index] * 40) + 2)
                    .opacity(isActive ? 1.0 : 0.3)
                    .animation(.easeInOut(duration: 0.1), value: levels[index])
            }
        }
    }
}

// MARK: - Conversation Context Card
struct ConversationContextCard: View {
    let conversations: [ConversationItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(conversations) { conversation in
                HStack {
                    if conversation.isUser {
                        Spacer()
                        Text(conversation.text)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(1)
                        
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(Color(hex: "00D4FF"))
                            .font(.caption)
                    } else {
                        Image(systemName: "cpu")
                            .foregroundColor(Color(hex: "00D4FF"))
                            .font(.caption)
                        
                        Text(conversation.text)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Conversation History View
struct ConversationHistoryView: View {
    let conversations: [ConversationItem]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(conversations) { conversation in
                            ConversationBubble(conversation: conversation)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Conversation History")
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

// MARK: - Conversation Bubble
struct ConversationBubble: View {
    let conversation: ConversationItem
    
    var body: some View {
        HStack {
            if conversation.isUser {
                Spacer(minLength: 50)
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(conversation.text)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "00D4FF"), Color(hex: "0099CC")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .foregroundColor(.white)
                    
                    Text(conversation.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "cpu")
                            .foregroundColor(Color(hex: "00D4FF"))
                            .font(.caption)
                            .padding(.top, 2)
                        
                        Text(conversation.text)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color(hex: "00D4FF").opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .foregroundColor(.white)
                    }
                    
                    Text(conversation.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.leading, 32)
                }
                
                Spacer(minLength: 50)
            }
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
        particles = (0..<150).map { _ in
            Particle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                ),
                duration: Double.random(in: 6...12)
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
    @ObservedObject var permissionManager: PermissionManager
    @EnvironmentObject var dependencies: AppDependencies
    @State private var currentStep = 0
    @State private var logoAnimationPhase = 0.0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ParticleSystemView()
                .ignoresSafeArea()
                .opacity(0.5)
            
            VStack(spacing: 40) {
                Spacer()
                
                // JARVIS Logo Animation
                ZStack {
                    Circle()
                        .stroke(Color(hex: "00D4FF").opacity(0.3), lineWidth: 2)
                        .frame(width: 120, height: 120)
                        .scaleEffect(1.0 + sin(logoAnimationPhase) * 0.1)
                    
                    Text("J")
                        .font(.system(size: 48, weight: .ultraLight))
                        .foregroundColor(Color(hex: "00D4FF"))
                        .opacity(currentStep >= 1 ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.5), value: currentStep)
                }
                .onAppear {
                    withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                        logoAnimationPhase = .pi * 2
                    }
                    
                    // Animate logo appearance
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        currentStep = 1
                    }
                }
                
                Text("JARVIS")
                    .font(.system(size: 72, weight: .ultraLight))
                    .foregroundColor(Color(hex: "00D4FF"))
                    .opacity(currentStep >= 1 ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 1.0).delay(0.5), value: currentStep)
                
                Text("Your Advanced AI Assistant")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))
                    .opacity(currentStep >= 1 ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 1.0).delay(1.0), value: currentStep)
                
                Spacer()
                
                VStack(spacing: 20) {
                    // Permission status
                    if !permissionManager.hasRequiredPermissions {
                        VStack(spacing: 16) {
                            Text("Required Permissions")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            PermissionRow(
                                icon: "mic.fill",
                                title: "Microphone",
                                description: "To hear your voice commands",
                                isGranted: permissionManager.microphonePermission == .granted
                            )
                            
                            PermissionRow(
                                icon: "waveform",
                                title: "Speech Recognition",
                                description: "To understand what you say",
                                isGranted: permissionManager.speechRecognitionPermission == .authorized
                            )
                            
                            Button(action: requestPermissions) {
                                HStack {
                                    Text("Grant Permissions")
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
                        }
                    } else {
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
                    }
                }
                .opacity(currentStep >= 1 ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 1.0).delay(1.5), value: currentStep)
                
                Spacer()
            }
        }
    }
    
    private func requestPermissions() {
        permissionManager.requestMicrophonePermission()
        permissionManager.requestSpeechRecognitionPermission()
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        withAnimation(.easeInOut(duration: 0.5)) {
            showOnboarding = false
        }
    }
}

// MARK: - Permission Row
struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    let isGranted: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isGranted ? Color(hex: "00FF88") : Color(hex: "FF6B35"))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Image(systemName: isGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isGranted ? Color(hex: "00FF88") : Color(hex: "FF6B35"))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Enhanced Settings View
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var permissionManager: PermissionManager
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text("JARVIS")
                                .font(.system(size: 32, weight: .thin))
                                .foregroundColor(Color(hex: "00D4FF"))
                            
                            Text("Advanced Configuration")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.top, 20)
                        
                        // Voice Settings
                        SettingsSection(title: "Voice Configuration") {
                            SettingRow(title: "Voice Selection", icon: "speaker.wave.2", value: "Adam (ElevenLabs)")
                            SettingRow(title: "Speech Speed", icon: "speedometer", value: "Normal")
                            SettingRow(title: "Voice Stability", icon: "slider.horizontal.3", value: "75%")
                        }
                        
                        // MCP Servers
                        SettingsSection(title: "Neural Network Connections") {
                            SettingRow(title: "MCP Servers", icon: "network", value: "2 Connected")
                            SettingRow(title: "Connection Status", icon: "wifi", value: "Online")
                            SettingRow(title: "Latency", icon: "timer", value: "45ms")
                        }
                        
                        // Permissions
                        SettingsSection(title: "Permissions & Privacy") {
                            PermissionSettingRow(
                                title: "Microphone",
                                icon: "mic.fill",
                                isGranted: permissionManager.microphonePermission == .granted
                            ) {
                                permissionManager.requestMicrophonePermission()
                            }
                            
                            PermissionSettingRow(
                                title: "Speech Recognition",
                                icon: "waveform",
                                isGranted: permissionManager.speechRecognitionPermission == .authorized
                            ) {
                                permissionManager.requestSpeechRecognitionPermission()
                            }
                        }
                        
                        // System Information
                        SettingsSection(title: "System Information") {
                            SettingRow(title: "Version", icon: "info.circle", value: "1.0.0")
                            SettingRow(title: "ElevenLabs Status", icon: "checkmark.circle", value: "Connected")
                            SettingRow(title: "Audio Engine", icon: "waveform.circle", value: "Active")
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
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

// MARK: - Settings Section
struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .foregroundColor(Color(hex: "00D4FF"))
                .padding(.horizontal, 4)
            
            VStack(spacing: 1) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Setting Row
struct SettingRow: View {
    let title: String
    let icon: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "00D4FF"))
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.white.opacity(0.7))
                .font(.system(size: 14))
            
            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.3))
                .font(.caption)
        }
        .padding()
        .background(Color.clear)
    }
}

// MARK: - Permission Setting Row
struct PermissionSettingRow: View {
    let title: String
    let icon: String
    let isGranted: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(isGranted ? Color(hex: "00FF88") : Color(hex: "FF6B35"))
                    .frame(width: 24)
                
                Text(title)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(isGranted ? "Granted" : "Denied")
                    .foregroundColor(isGranted ? Color(hex: "00FF88") : Color(hex: "FF6B35"))
                    .font(.system(size: 14))
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.3))
                    .font(.caption)
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - App Dependencies (Enhanced)
class AppDependencies: ObservableObject {
    // ElevenLabs service would be initialized here
    // MCP services would be initialized here
    // Other services...
    
    init() {
        print("🚀 JARVIS Advanced Dependencies initialized")
        setupServices()
    }
    
    private func setupServices() {
        // Initialize ElevenLabs service
        // Initialize MCP bridge
        // Setup other services
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
