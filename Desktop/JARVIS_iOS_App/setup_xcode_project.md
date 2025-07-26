# 🚀 JARVIS iOS App - Xcode Setup Guide

## Quick Setup Checklist

### 1. Create New Xcode Project
- [ ] Open Xcode
- [ ] Create new iOS app project
- [ ] Name: "JARVIS"
- [ ] Bundle ID: `com.yourcompany.jarvis`
- [ ] Language: Swift
- [ ] Interface: SwiftUI
- [ ] Minimum iOS: 15.0

### 2. Import Project Files
Copy these files to your Xcode project:

**From `SwiftUI_Implementation/`:**
- [ ] `JARVISApp.swift` → Replace default App.swift
- [ ] `JARVIS_SwiftUI_Views.swift` → Add to project
- [ ] `JARVIS_CoreServices.swift` → Add to project  
- [ ] `JARVIS_UseCases_Implementation.swift` → Add to project

**From `MCP_Integration/`:**
- [ ] `MCP-iOS-Models.swift` → Add to project
- [ ] `MCP-MessageHandler.swift` → Add to project
- [ ] `MCP-SwiftUI-Views.swift` → Add to project

**Root files:**
- [ ] `Configuration.swift` → Add to project
- [ ] `Info.plist` → Replace default Info.plist

### 3. Add Package Dependencies
In Xcode: File → Add Package Dependencies

Add these packages:
```
https://github.com/daltoniam/Starscream.git (WebSocket)
https://github.com/evgenyneu/keychain-swift.git (Keychain)
https://github.com/airbnb/lottie-ios.git (Animations - Optional)
```

### 4. Configure Project Settings

**Target Settings:**
- [ ] Deployment Target: iOS 15.0
- [ ] Supported Orientations: Portrait, Landscape Left/Right
- [ ] Status Bar Style: Light Content

**Capabilities:**
- [ ] Background Modes: Audio, Background Processing
- [ ] Keychain Sharing: Enable
- [ ] Push Notifications: Enable (optional)

### 5. Add Your API Keys

Edit `Configuration.swift`:
```swift
static let elevenLabsAPIKey = "YOUR_ACTUAL_API_KEY_HERE"
```

**Get ElevenLabs API Key:**
1. Sign up at https://elevenlabs.io
2. Go to Profile → API Keys
3. Copy your key and paste it in Configuration.swift

### 6. Test Build

- [ ] Build project (⌘+B)
- [ ] Fix any import errors
- [ ] Run on simulator (⌘+R)
- [ ] Test on physical device for audio

### 7. Common Issues & Fixes

**Missing Imports:**
Add these imports to files as needed:
```swift
import SwiftUI
import AVFoundation
import Speech
import Combine
```

**Audio Permission:**
The app will request microphone permission on first launch.

**Build Errors:**
- Check all files are added to target
- Verify package dependencies are resolved
- Clean build folder (⌘+Shift+K)

### 8. First Run Experience

When you run the app:
1. **Onboarding** - Set up voice and permissions
2. **Voice Test** - Tap the center circle to test recording
3. **Settings** - Configure ElevenLabs voice settings
4. **MCP Setup** - Add your server connections

### 9. Next Steps After Setup

- [ ] Test voice recording and playback
- [ ] Configure ElevenLabs voice settings
- [ ] Set up MCP server connections
- [ ] Customize UI colors and animations
- [ ] Test on multiple devices

## 🎯 Quick Test Commands

Once running, try these voice commands:
- "Hello JARVIS"
- "What time is it?"
- "Tell me a joke"

## 📞 Support

If you encounter issues:
1. Check the console for error messages
2. Verify API keys are correct
3. Test microphone permissions
4. Try running on physical device (not simulator) for audio

---

**🚀 You're ready to launch your JARVIS app!**