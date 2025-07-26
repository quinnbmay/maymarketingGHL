# 🤖 JARVIS iOS App

A beautiful JARVIS-inspired iOS voice assistant app with ElevenLabs integration and cutting-edge UI design.

## ✨ Features

- **Voice Recognition**: Real-time speech-to-text using iOS Speech Framework
- **Voice Synthesis**: Natural voice responses using ElevenLabs API
- **Beautiful UI**: Holographic glass morphism effects with animated particles
- **Responsive Design**: Optimized for all iPhone sizes
- **Privacy-First**: On-device speech recognition for enhanced privacy
- **Dark Mode**: Optimized for dark theme with stunning visual effects

## 🚀 Quick Start

### 1. Prerequisites
- Xcode 15.0+
- iOS 15.0+ deployment target
- ElevenLabs API key (free tier available)

### 2. Setup
1. **Clone or Download** the project
2. **Open** `Jarvis.xcodeproj` in Xcode
3. **Configure** your ElevenLabs API key in `Configuration.swift`
4. **Build and run** on your device or simulator

### 3. Get ElevenLabs API Key
1. Sign up at [ElevenLabs](https://elevenlabs.io/)
2. Go to your profile → API Key
3. Copy your API key
4. Replace `YOUR_ELEVENLABS_API_KEY_HERE` in `Configuration.swift`

## 📱 How to Use

### First Launch
1. **Grant Permissions**: Allow microphone and speech recognition when prompted
2. **Complete Onboarding**: Follow the setup guide
3. **Start Talking**: Tap the voice button and speak!

### Voice Commands
Try these commands:
- "Hello JARVIS"
- "What's the weather like?"
- "Tell me a joke"
- "What time is it?"
- "How are you today?"
- "What can you do?"

## 🛠️ Project Structure

```
Jarvis/
├── Jarvis.xcodeproj/          # Xcode project file
├── Jarvis/
│   ├── JarvisApp.swift        # Main app entry point
│   ├── ContentView.swift      # Main UI with voice assistant
│   ├── Configuration.swift    # API keys and settings
│   ├── ElevenLabsService.swift # Voice synthesis service
│   ├── Persistence.swift      # Core Data setup
│   └── Assets.xcassets/       # App icons and colors
├── JarvisTests/               # Unit tests
└── JarvisUITests/             # UI tests
```

## 🔧 Configuration

### API Keys
Edit `Configuration.swift`:
```swift
static let elevenLabsAPIKey = "your_actual_api_key_here"
```

### Voice Settings
Customize voice parameters:
```swift
static let defaultStability = 0.75
static let defaultSimilarityBoost = 0.75
static let defaultVoiceID = "pNInz6obpgDQGcFmaJgB" // Adam voice
```

## 🎨 UI Features

- **Particle System**: Animated background particles
- **Glass Morphism**: Holographic interface effects
- **Voice Visualizer**: Real-time audio visualization
- **Smooth Animations**: Fluid transitions and interactions
- **Responsive Design**: Works on all iPhone sizes

## 🔒 Privacy & Permissions

The app requires:
- **Microphone Access**: To hear your voice commands
- **Speech Recognition**: To convert speech to text

All processing is done on-device for privacy.

## 🐛 Troubleshooting

### Build Issues
1. **Clean Build**: Xcode → Product → Clean Build Folder
2. **Reset Simulator**: Simulator → Device → Erase All Content and Settings
3. **Check Permissions**: Ensure microphone and speech recognition are enabled

### Voice Issues
1. **Check API Key**: Verify ElevenLabs API key is correct
2. **Internet Connection**: Ensure stable internet for voice synthesis
3. **Microphone**: Test microphone in other apps

### Performance
1. **Close Other Apps**: Free up memory
2. **Restart Device**: Clear any background processes
3. **Update iOS**: Ensure latest iOS version

## 📄 License

This project is for educational and personal use.

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

---

**Ready to experience the future of voice assistants?** 🚀

Open `Jarvis.xcodeproj` in Xcode and start building your personal JARVIS! 