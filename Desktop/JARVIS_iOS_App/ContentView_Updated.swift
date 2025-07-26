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
        // Request microphone permission
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                print("✅ Microphone permission granted")
            } else {
                print("❌ Microphone permission denied")
            }
        }
        
        // Request speech recognition permission
        SFSpeechRecognizer.requestAuthorization { status in
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

// MARK: - Simple Voice Assistant ViewModel
class VoiceAssistantViewModel: ObservableObject {
    @Published var isListening = false
    @Published var statusText = "Tap to speak"
    @Published var transcribedText = ""
    
    func startListening() {
        isListening = true
        statusText = "Listening..."
        // Add your speech recognition logic here
    }
    
    func stopListening() {
        isListening = false
        statusText = "Tap to speak"
        transcribedText = ""
    }
    
    func startContinuousListening() {
        isListening = true
        statusText = "Continuous listening..."
        // Add continuous listening logic here
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

// MARK: - Simple Onboarding View
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

// MARK: - Simple Settings View
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
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

// MARK: - App Dependencies (Simplified)
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