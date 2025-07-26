# JARVIS iOS App - UI/UX Design Specifications

## Design Philosophy
A futuristic, AI-powered voice assistant app inspired by JARVIS from Iron Man, featuring holographic aesthetics, fluid animations, and cutting-edge interaction patterns. The design emphasizes minimalism, sophistication, and advanced technology while maintaining iOS Human Interface Guidelines.

## Color Palette
- **Primary Background**: #000000 (Pure Black)
- **Secondary Background**: #0A0A0F (Deep Space)
- **Accent Blue**: #00D4FF (Electric Cyan)
- **Secondary Accent**: #FF6B35 (Plasma Orange)
- **Tertiary Accent**: #7B68EE (Quantum Purple)
- **Success**: #00FF88 (Matrix Green)
- **Warning**: #FFB700 (Arc Reactor Gold)
- **Error**: #FF3366 (Critical Red)
- **Text Primary**: #FFFFFF (95% opacity)
- **Text Secondary**: #B8B8C8 (70% opacity)
- **Glass Effect**: rgba(255, 255, 255, 0.05)

## Typography
- **Display**: SF Pro Display (System)
  - Hero: 72pt Ultra Light
  - Large Title: 34pt Bold
  - Title 1: 28pt Semibold
  - Title 2: 22pt Medium
  - Title 3: 20pt Regular
- **Body**: SF Pro Text
  - Body: 17pt Regular
  - Callout: 16pt Regular
  - Subhead: 15pt Semibold
  - Footnote: 13pt Regular
  - Caption: 12pt Regular
- **Monospace**: SF Mono (for technical displays)
  - Code: 14pt Medium

## 1. Main Voice Interaction Screen

### Layout Structure
- **Safe Area Insets**: Standard iOS (top: 47pt, bottom: 34pt on iPhone X+)
- **Content Padding**: 20pt horizontal, 24pt vertical

### Components

#### Background
- Animated particle system with 200-300 glowing particles
- Particles move in slow, orbital patterns
- Subtle gradient overlay: radial from center (#00D4FF at 0% opacity to #000000 at 100%)
- Gaussian blur effect on particles: 8pt radius

#### Central Voice Visualizer (400pt × 400pt)
- **Position**: Center of screen
- **Idle State**: 
  - Circular ring: 2pt stroke, #00D4FF at 30% opacity
  - Inner circle: 120pt diameter, filled with radial gradient
  - Subtle pulse animation: scale 1.0 to 1.05, duration 3s, ease-in-out
- **Listening State**:
  - Concentric rings expanding outward
  - Ring count: 3-5 based on volume
  - Ring animation: opacity 100% to 0%, scale 1.0 to 1.5, duration 1.5s
  - Core glows brighter: #00D4FF at 80% opacity
- **Processing State**:
  - Rotating segments (8 pieces) around center
  - Rotation speed: 60rpm
  - Segments fade in/out sequentially
  - Loading dots orbit around edge
- **Speaking State**:
  - Audio waveform visualization
  - 64 frequency bars arranged in circle
  - Bar height: 20-120pt based on frequency
  - Smooth interpolation between values
  - Rainbow gradient across frequencies

#### Status Label
- **Position**: 40pt below visualizer
- **Font**: SF Pro Display, 20pt Medium
- **States**:
  - "Tap to speak" (idle)
  - "Listening..." (active)
  - "Processing..." (thinking)
  - "Speaking..." (responding)
- **Animation**: Fade transition, 0.3s duration

#### Conversation Context
- **Position**: 80pt from top
- **Size**: Full width minus 40pt padding
- **Style**: Glass morphism card
  - Background: rgba(255, 255, 255, 0.05)
  - Border: 1pt, rgba(255, 255, 255, 0.1)
  - Backdrop blur: 20pt
  - Corner radius: 16pt
- **Content**: Last 3 conversation turns
- **Typography**: SF Pro Text, 15pt Regular
- **Max height**: 120pt with fade overflow

#### Action Buttons
- **Position**: 100pt from bottom
- **Layout**: Horizontal stack, 16pt spacing
- **Button Size**: 60pt × 60pt
- **Style**: 
  - Glass background with 40% opacity
  - Icon: SF Symbols, 28pt
  - Tap feedback: Scale to 0.95, haptic impact
- **Buttons**:
  - History (clock.arrow.circlepath)
  - Settings (gearshape.fill)
  - Keyboard (keyboard)
  - Commands (list.bullet.rectangle)

### Animations
- **Entry**: Elements fade in with stagger, 0.1s delay between
- **Voice Activation**: Ripple effect from touch point
- **State Transitions**: Morphing animations between visualizer states
- **Background Particles**: Respond to voice amplitude

### Gestures
- **Tap**: Activate voice input
- **Long Press**: Continuous listening mode
- **Swipe Up**: Show full conversation
- **Swipe Down**: Minimize to compact mode
- **Pinch**: Zoom visualizer
- **3D Touch/Haptic Touch**: Quick actions menu

## 2. Settings Screen

### Navigation
- **Header Height**: 96pt (Large Title)
- **Back Button**: Custom glass style
- **Title**: "JARVIS Settings"

### Sections

#### Voice Configuration
- **Section Header**: "Voice Personality"
- **Voice Selector**:
  - Grid layout: 2 columns
  - Card size: (screen width - 60) / 2
  - Card height: 140pt
  - Voice preview button: 44pt
  - Waveform visualization preview
  - Selected state: Glowing border (2pt, #00D4FF)
- **Voice Parameters**:
  - Speed Slider: 0.5x to 2.0x
  - Pitch Slider: -12 to +12 semitones
  - Custom slider thumb: 28pt circular with glow

#### MCP Server Configuration
- **Section Header**: "Neural Network Connection"
- **Server List**:
  - Table style with glass rows
  - Row height: 72pt
  - Connection status indicator: 8pt circle
  - Latency display: Real-time ms
  - Signal strength bars
- **Add Server Button**:
  - Floating action style
  - Position: Bottom right, 20pt margin
  - Size: 56pt diameter
  - Plus icon with rotation on tap

#### Appearance
- **Theme Selector**:
  - Segmented control: Dark | Auto | Custom
  - Custom theme builder with color pickers
- **Particle Density**: Slider 0-500 particles
- **Animation Speed**: Slider 0.5x-2.0x
- **Haptic Feedback**: Toggle switches

#### Privacy & Security
- **Biometric Lock**: Face ID/Touch ID toggle
- **Data Retention**: Dropdown (1 day, 1 week, 1 month, Forever)
- **Analytics**: Toggle with explanation text

### Visual Elements
- **Section Spacing**: 32pt between sections
- **Row Animations**: Slide in from right on appear
- **Toggle Switches**: Custom design with glow effect
- **Sliders**: Glass track with plasma-like fill

## 3. History/Conversation View

### Layout
- **Style**: Full-screen modal with gesture dismissal
- **Background**: Blurred main screen with 80% opacity overlay

### Message Bubbles
- **User Messages**:
  - Alignment: Right
  - Background: Linear gradient (#00D4FF to #0099CC)
  - Padding: 16pt horizontal, 12pt vertical
  - Corner radius: 20pt (bottom-right: 4pt)
  - Max width: 75% of screen
- **JARVIS Messages**:
  - Alignment: Left
  - Background: Glass effect with holographic shimmer
  - Border: 1pt gradient stroke
  - Avatar: 40pt animated arc reactor icon
- **Timestamp**: 
  - Center aligned between message groups
  - Font: SF Pro Text, 12pt Regular
  - Color: 50% white opacity

### Interactive Elements
- **Message Actions** (Long press):
  - Copy text
  - Share
  - Regenerate response
  - Delete
- **Search Bar**:
  - Position: Sticky top
  - Height: 44pt
  - Glass background
  - Real-time search with highlighting
- **Filter Chips**:
  - Below search: Commands, Questions, Responses
  - Chip style: Rounded rect, 28pt height
  - Selected state: Filled background

### Performance
- **Virtual Scrolling**: Only render visible + 3 messages
- **Lazy Loading**: Load 50 messages at a time
- **Image Caching**: For any media responses

## 4. Onboarding Flow

### Screen 1: Welcome
- **Hero Animation**: JARVIS logo assembly
  - Duration: 2.5s
  - Pieces fly in from edges
  - Holographic scan effect
- **Title**: "Welcome to JARVIS"
- **Subtitle**: "Your Advanced AI Assistant"
- **CTA Button**: "Initialize System"

### Screen 2: Voice Selection
- **Interactive Demo**: Live voice preview
- **Carousel**: Swipeable voice options
- **Visual Feedback**: Waveform for each voice
- **Skip Option**: Top right

### Screen 3: Permissions
- **Microphone Access**: Animated icon with pulse
- **Notification Permission**: Optional
- **Explanation Cards**: Why each is needed
- **Grant Button**: Prominent with glow effect

### Screen 4: MCP Setup
- **Auto-Discovery**: Scanning animation
- **Manual Entry**: Collapsible option
- **Test Connection**: Real-time status
- **Success Animation**: Neural network visualization

### Screen 5: Personalization
- **Name Input**: "What should I call you?"
- **Preference Quick Settings**:
  - Wake word
  - Default commands
  - Theme preference
- **Completion**: Dramatic initialization sequence

### Animations
- **Page Transitions**: 3D flip effect
- **Progress Indicator**: Bottom dots with energy flow
- **Skip Animation**: Fast-forward particle effect

## 5. Custom Controls and Components

### Glass Button
```
- Size: 44pt height minimum
- Background: rgba(255, 255, 255, 0.08)
- Border: 1pt, rgba(255, 255, 255, 0.2)
- Backdrop filter: blur(20pt)
- Corner radius: 12pt
- Pressed state: scale(0.97), background alpha 0.12
- Disabled state: 30% opacity
```

### Plasma Slider
```
- Track height: 6pt
- Track background: rgba(255, 255, 255, 0.1)
- Fill: Linear gradient with animated glow
- Thumb: 28pt circle with outer glow ring
- Value label: Appears above on drag
```

### Holographic Toggle
```
- Size: 51pt × 31pt (iOS standard)
- Off state: Glass background
- On state: Gradient fill with pulse
- Transition: 0.3s with light trail effect
- Knob: Contains mini arc reactor graphic
```

### Neural Network Loader
```
- Size: 64pt × 64pt
- Animation: Interconnected nodes with data flow
- Node count: 8-12
- Connection animation: Energy pulses
- Colors: Cycle through accent palette
```

### Command Card
```
- Height: 80pt
- Background: Glass with holographic shimmer
- Icon: 40pt, left aligned
- Title: SF Pro Text, 17pt Semibold
- Description: SF Pro Text, 14pt Regular
- Tap animation: Ripple from touch point
```

## 6. Dark Mode Optimizations

### Pure Black Benefits
- **OLED Optimization**: True black (#000000) for battery saving
- **Contrast Ratios**: All text meets WCAG AAA standards
- **Glow Effects**: Enhanced visibility in dark environments

### Adaptive Elements
- **Particle Brightness**: Reduced by 20% in dark mode
- **Glass Effects**: Increased blur for better readability
- **Accent Colors**: Slightly desaturated for comfort
- **Shadow Effects**: Replaced with glow effects

### Ambient Light Response
- **Brightness Sensor**: Adjust UI brightness automatically
- **Color Temperature**: Warmer tones in low light
- **Animation Speed**: Slower in dark environments

## 7. Accessibility Considerations

### VoiceOver Support
- **All Elements**: Proper labels and hints
- **Gestures**: Alternative navigation methods
- **Announcements**: State changes announced
- **Rotor Actions**: Custom actions for complex controls

### Visual Accommodations
- **High Contrast Mode**: Simplified UI with solid colors
- **Reduce Motion**: Static visualizer option
- **Larger Text**: Scales up to 200%
- **Color Blind Modes**: Alternative color schemes

### Motor Accommodations
- **Touch Targets**: Minimum 44pt × 44pt
- **Gesture Alternatives**: All gestures have button alternatives
- **Dwell Control**: Support for switch control
- **Voice Control**: Full navigation via voice

### Hearing Accommodations
- **Visual Feedback**: All audio has visual equivalent
- **Haptic Patterns**: Distinct patterns for different events
- **Captions**: For any video content
- **Visual Alerts**: Flash or banner notifications

## 8. Gesture Controls and Haptic Feedback

### Gesture Dictionary
- **Single Tap**: Primary action
- **Double Tap**: Quick command menu
- **Long Press**: Context menu
- **3D Touch**: Peek and pop for messages
- **Swipe Left/Right**: Navigate between screens
- **Swipe Up/Down**: Scroll or dismiss
- **Pinch**: Zoom visualizer or text
- **Rotate**: Adjust visualizer parameters
- **Shake**: Undo last action

### Haptic Patterns

#### Success Feedback
- **Pattern**: Light (0.3) → Medium (0.6) → Light (0.3)
- **Duration**: 200ms total
- **Use**: Command completion, connection success

#### Error Feedback
- **Pattern**: Heavy (1.0) → Heavy (1.0) → Heavy (1.0)
- **Duration**: 300ms total
- **Use**: Errors, failed commands

#### Selection Feedback
- **Pattern**: Light (0.4) single tap
- **Duration**: 50ms
- **Use**: Button presses, selections

#### Processing Feedback
- **Pattern**: Continuous light (0.2) pulse
- **Duration**: Variable
- **Use**: During processing/loading

#### Notification Feedback
- **Pattern**: Medium (0.6) → Light (0.3) → Medium (0.6)
- **Duration**: 250ms
- **Use**: Incoming messages, alerts

### Edge Gestures
- **Left Edge Swipe**: Back navigation
- **Right Edge Swipe**: Forward navigation
- **Top Edge Pull**: Notification center
- **Bottom Edge Swipe**: Home indicator

## Implementation Notes

### Performance Targets
- **Launch Time**: < 1.5 seconds
- **Animation FPS**: Consistent 60fps (120fps on ProMotion)
- **Memory Usage**: < 150MB baseline
- **Battery Impact**: < 5% per hour active use

### Technical Considerations
- **Metal Shaders**: For particle effects and visualizers
- **Core Animation**: For smooth transitions
- **AVAudioEngine**: For real-time audio processing
- **Vision Framework**: For gesture recognition
- **Core Haptics**: For precise feedback control

### Testing Requirements
- **Device Coverage**: iPhone 12 and newer
- **iOS Versions**: iOS 15.0+
- **Accessibility**: Full VoiceOver navigation
- **Performance**: Profiling on lowest supported device
- **Battery**: Extended use testing
- **Network**: Offline mode support