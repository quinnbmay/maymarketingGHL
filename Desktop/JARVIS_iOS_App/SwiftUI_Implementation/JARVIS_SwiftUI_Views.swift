// JARVIS iOS App - Main SwiftUI Views Implementation

import SwiftUI
import Combine
import AVFoundation

// MARK: - Main Voice Assistant View
struct VoiceAssistantView: View {
    @StateObject private var viewModel: VoiceAssistantViewModel
    @StateObject private var audioVisualizer = AudioVisualizer()
    @State private var showSettings = false
    @State private var animationPhase = 0.0
    
    init(dependencies: AppDependencies) {
        _viewModel = StateObject(wrappedValue: VoiceAssistantViewModel(dependencies: dependencies))
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            BackgroundGradient()
            
            VStack(spacing: 0) {
                // Top bar
                TopNavigationBar(showSettings: $showSettings)
                    .padding(.horizontal)
                
                // Conversation history
                ConversationScrollView(conversations: viewModel.conversationHistory)
                    .padding(.horizontal)
                
                Spacer()
                
                // Voice visualization
                VoiceVisualizationView(
                    audioLevels: audioVisualizer.levels,
                    isListening: viewModel.isListening,
                    animationPhase: animationPhase
                )
                .frame(height: 200)
                
                // Current transcription
                if !viewModel.transcribedText.isEmpty {
                    TranscriptionView(text: viewModel.transcribedText)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // Voice control button
                VoiceControlButton(
                    isListening: viewModel.isListening,
                    action: viewModel.toggleListening
                )
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            startAnimations()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
    
    private func startAnimations() {
        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
            animationPhase = 1.0
        }
    }
}

// MARK: - Background Gradient
struct BackgroundGradient: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.07, green: 0.07, blue: 0.12),
                Color(red: 0.13, green: 0.13, blue: 0.18)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay(
            // Animated particles
            ParticleEffectView()
                .blendMode(.screen)
                .opacity(0.3)
        )
    }
}

// MARK: - Voice Visualization
struct VoiceVisualizationView: View {
    let audioLevels: [Float]
    let isListening: Bool
    let animationPhase: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Circular ring animation
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 2
                        )
                        .scaleEffect(isListening ? 1.0 + Double(index) * 0.3 : 0.8)
                        .opacity(isListening ? 0.3 - Double(index) * 0.1 : 0)
                        .animation(
                            .easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                            value: isListening
                        )
                }
                
                // Audio waveform
                if isListening {
                    WaveformView(
                        audioLevels: audioLevels,
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
                    .transition(.opacity)
                }
                
                // Center orb
                Circle()
                    .fill(
                        RadialGradient(
                            colors: isListening ? [.blue, .purple] : [.gray, .gray.opacity(0.7)],
                            center: .center,
                            startRadius: 5,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: isListening ? .blue : .clear, radius: 20)
                    .scaleEffect(isListening ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: isListening)
            }
        }
    }
}

// MARK: - Waveform Visualization
struct WaveformView: View {
    let audioLevels: [Float]
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        Canvas { context, size in
            let barWidth = size.width / CGFloat(audioLevels.count)
            let centerY = size.height / 2
            
            for (index, level) in audioLevels.enumerated() {
                let x = CGFloat(index) * barWidth
                let barHeight = CGFloat(level) * size.height * 0.8
                
                let rect = CGRect(
                    x: x,
                    y: centerY - barHeight / 2,
                    width: barWidth - 2,
                    height: barHeight
                )
                
                let path = Path(roundedRect: rect, cornerRadius: 2)
                
                context.fill(
                    path,
                    with: .linearGradient(
                        Gradient(colors: [.blue, .purple]),
                        startPoint: CGPoint(x: rect.midX, y: rect.minY),
                        endPoint: CGPoint(x: rect.midX, y: rect.maxY)
                    )
                )
            }
        }
    }
}

// MARK: - Voice Control Button
struct VoiceControlButton: View {
    let isListening: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: isListening ? [.blue, .purple] : [.gray, .gray.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 80, height: 80)
                
                // Inner circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isListening ? [.blue, .purple] : [.gray, .gray.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                
                // Microphone icon
                Image(systemName: isListening ? "mic.fill" : "mic")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            pressing: { pressing in
                isPressed = pressing
            },
            perform: {}
        )
    }
}

// MARK: - Conversation View
struct ConversationScrollView: View {
    let conversations: [ConversationEntry]
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(conversations) { entry in
                        ConversationBubble(entry: entry)
                            .id(entry.id)
                    }
                }
                .padding(.vertical)
            }
            .onChange(of: conversations.count) { _ in
                withAnimation {
                    proxy.scrollTo(conversations.last?.id, anchor: .bottom)
                }
            }
        }
    }
}

// MARK: - Conversation Bubble
struct ConversationBubble: View {
    let entry: ConversationEntry
    
    var body: some View {
        HStack {
            if entry.isUser {
                Spacer()
            }
            
            VStack(alignment: entry.isUser ? .trailing : .leading, spacing: 4) {
                Text(entry.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(entry.isUser ? Color.blue : Color.gray.opacity(0.2))
                    )
                    .foregroundColor(entry.isUser ? .white : .primary)
                
                Text(entry.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !entry.isUser {
                Spacer()
            }
        }
    }
}

// MARK: - Transcription View
struct TranscriptionView: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .foregroundColor(.white.opacity(0.9))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .padding(.horizontal)
            .padding(.bottom, 20)
    }
}

// MARK: - Top Navigation Bar
struct TopNavigationBar: View {
    @Binding var showSettings: Bool
    
    var body: some View {
        HStack {
            Text("JARVIS")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Spacer()
            
            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.vertical)
    }
}

// MARK: - Particle Effect View
struct ParticleEffectView: View {
    @State private var particles: [Particle] = []
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let currentTime = timeline.date.timeIntervalSince1970
                
                for particle in particles {
                    let progress = (currentTime - particle.creationTime) / particle.lifetime
                    guard progress <= 1 else { continue }
                    
                    let opacity = 1 - progress
                    let scale = particle.scale * (1 - progress * 0.5)
                    
                    context.opacity = opacity
                    
                    let rect = CGRect(
                        x: particle.position.x - particle.size / 2,
                        y: particle.position.y - particle.size / 2,
                        width: particle.size,
                        height: particle.size
                    )
                    
                    context.fill(
                        Circle().path(in: rect),
                        with: .color(particle.color)
                    )
                }
            }
            .onAppear {
                createParticles()
            }
        }
    }
    
    private func createParticles() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            let particle = Particle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                ),
                size: CGFloat.random(in: 2...6),
                color: Color.blue.opacity(0.5),
                scale: CGFloat.random(in: 0.5...1.5),
                lifetime: Double.random(in: 2...5),
                creationTime: Date().timeIntervalSince1970
            )
            
            particles.append(particle)
            particles = particles.filter { 
                (Date().timeIntervalSince1970 - $0.creationTime) <= $0.lifetime 
            }
        }
    }
}

// MARK: - Supporting Types
struct Particle {
    let position: CGPoint
    let size: CGFloat
    let color: Color
    let scale: CGFloat
    let lifetime: Double
    let creationTime: Double
}

struct ConversationEntry: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let timestamp: Date
}

// MARK: - Audio Visualizer
class AudioVisualizer: ObservableObject {
    @Published var levels: [Float] = Array(repeating: 0, count: 50)
    private var displayLink: CADisplayLink?
    private let audioEngine = AVAudioEngine()
    
    func startVisualizing() {
        setupAudioEngine()
        displayLink = CADisplayLink(target: self, selector: #selector(updateLevels))
        displayLink?.add(to: .current, forMode: .common)
    }
    
    func stopVisualizing() {
        displayLink?.invalidate()
        displayLink = nil
        audioEngine.stop()
    }
    
    private func setupAudioEngine() {
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }
        
        do {
            try audioEngine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        
        let channelDataValue = channelData.pointee
        let channelDataValueArray = stride(from: 0, to: Int(buffer.frameLength), by: buffer.stride)
            .map { channelDataValue[$0] }
        
        let rms = sqrt(channelDataValueArray.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))
        let avgPower = 20 * log10(rms)
        let normalizedPower = (avgPower + 60) / 60 // Normalize from -60 to 0 dB
        
        DispatchQueue.main.async {
            self.levels.append(max(0, normalizedPower))
            if self.levels.count > 50 {
                self.levels.removeFirst()
            }
        }
    }
    
    @objc private func updateLevels() {
        // Trigger UI update
        objectWillChange.send()
    }
}