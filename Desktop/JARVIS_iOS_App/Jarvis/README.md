# 🤖 JARVIS iOS App

A beautiful JARVIS-inspired iOS voice assistant app with ElevenLabs integration and cutting-edge UI design.

## ✨ Features

- **Voice Recognition**: Real-time speech-to-text using iOS Speech Framework
- **Voice Synthesis**: Natural voice responses using ElevenLabs API
- **Beautiful UI**: Holographic glass morphism effects with animated particles
- **Responsive Design**: Optimized for all iPhone sizes
- **Privacy-First**: On-device speech recognition for enhanced privacy

## 🚀 Quick Start

### 1. Prerequisites
- Xcode 15.0+
- iOS 15.0+ deployment target
- ElevenLabs API key (free tier available)

### 2. Setup
1. Open `Jarvis.xcodeproj` in Xcode
2. Configure your ElevenLabs API key in `Configuration.swift`
3. Build and run on your device

### 3. Get ElevenLabs API Key
1. Sign up at [ElevenLabs](https://elevenlabs.io/)
2. Go to your profile and copy your API key
3. Replace `YOUR_ELEVENLABS_API_KEY_HERE` in `Configuration.swift`

## 🎯 How to Use

1. **First Launch**: Complete the onboarding process
2. **Voice Commands**: Tap the microphone button and speak
3. **Responses**: JARVIS will respond with natural voice synthesis
4. **Continuous Mode**: Enable continuous listening for hands-free operation

## 🔧 Configuration

### API Keys
Edit `Configuration.swift` to set your API keys:
```swift
static let elevenLabsAPIKey = "your_actual_api_key_here"
```

### Voice Settings
Customize voice parameters in `Configuration.swift`:
```swift
static let defaultStability = 0.75
static let defaultSimilarityBoost = 0.75
static let defaultStyle = 0.0
```

## 🏗️ Project Structure

```
Jarvis/
├── Jarvis/
│   ├── ContentView.swift          # Main UI and voice assistant
│   ├── Configuration.swift        # API keys and settings
│   ├── ElevenLabsService.swift    # Voice synthesis service
│   ├── JarvisApp.swift           # App entry point
│   └── Assets.xcassets/          # App icons and colors
├── Jarvis.xcodeproj/             # Xcode project file
└── README.md                     # This file
```

## 🎨 UI Components

- **ParticleSystemView**: Animated background particles
- **GlassMorphismCard**: Holographic card effects
- **VoiceButton**: Interactive microphone button
- **OnboardingView**: First-time user experience

## 🔒 Permissions

The app requires these permissions (already configured):
- **Microphone**: For voice input
- **Speech Recognition**: For converting speech to text

## 🐛 Troubleshooting

### Build Issues
- Ensure Xcode 15.0+ is installed
- Clean build folder (Cmd+Shift+K)
- Reset iOS Simulator if needed

### Voice Recognition Issues
- Check microphone permissions in Settings
- Ensure device has internet connection
- Verify ElevenLabs API key is valid

### Audio Issues
- Check device volume
- Ensure no other apps are using audio
- Try restarting the app

## 📱 Supported Devices

- iPhone running iOS 15.0+
- iPad running iPadOS 15.0+
- Optimized for iPhone 12 and newer

## 🔄 Recent Fixes

✅ **Fixed Info.plist conflicts** - Removed custom Info.plist and configured project settings
✅ **Added missing permissions** - Microphone and Speech Recognition
✅ **Integrated ElevenLabs service** - Complete voice synthesis implementation
✅ **Enhanced UI components** - Glass morphism effects and animations
✅ **Added error handling** - Proper error messages and fallbacks

## 🚀 Next Steps

1. **Add more voice commands** - Expand the command processing logic
2. **Integrate with other APIs** - Weather, calendar, smart home
3. **Add user preferences** - Voice selection, UI themes
4. **Implement offline mode** - Basic responses without internet

## 📄 License

This project is for educational purposes. Please respect ElevenLabs' terms of service.

---

**Built with ❤️ using SwiftUI and ElevenLabs** 