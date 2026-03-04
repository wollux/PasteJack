# PasteJack

**Paste anywhere. Even where you can't.**

A native macOS menu bar utility that simulates keyboard input from your clipboard. PasteJack types your text character by character using simulated keystrokes — bypassing paste-blocking in IPMI/iLO/iDRAC consoles, RDP sessions, VMs without guest tools, and web forms that intercept `Cmd+V`.

Built with Swift and SwiftUI. No dependencies. Runs entirely offline.

---

## The Problem

If you've ever worked with remote server management, you know the pain:

- **IPMI / iLO / iDRAC** web consoles have no clipboard support
- **RDP sessions** without clipboard redirection block paste
- **Virtual machines** without guest tools can't share the clipboard
- **Web forms** that intercept the paste event with JavaScript
- **Secure terminals** that disable paste for compliance reasons

Copying a 64-character SSH key or a long server command by hand is slow, error-prone, and frustrating.

## The Solution

PasteJack reads your clipboard and sends each character as a simulated keystroke via the macOS Accessibility API (`CGEvent`). The target application sees real keyboard input — not a paste event. It works everywhere a physical keyboard works.

The key technical insight: `CGEvent.keyboardSetUnicodeString()` sends Unicode characters directly, bypassing keyboard layout mapping entirely. This means PasteJack works with **any keyboard layout** (US, German, French, etc.) and **any character** — including `@`, `€`, `{}`, `[]`, `\`, `~`, and accented characters like `ü`, `ö`, `ä`, `é`, `ñ`.

---

## Features

### Core

| Feature | Description |
|---------|-------------|
| **Paste as Keystrokes** | Types clipboard contents character by character via `CGEvent` — works in any app that accepts keyboard input |
| **Copy from Screen (OCR)** | Select any screen region, extract text with Apple Vision, edit it, copy or type it directly |
| **Type Selected Text** | Grabs the currently selected text (via simulated Cmd+C) and types it into another window |
| **Any Keyboard Layout** | Uses Unicode injection instead of keycode mapping — works with US, German, French, and every other layout |
| **Cancel Anytime** | Press Escape during typing to stop immediately |

### Typing Engine

| Feature | Description |
|---------|-------------|
| **Configurable Speed** | 5ms to 200ms delay per keystroke — tune for your target (IPMI: 50–100ms, RDP over WAN: 30–50ms) |
| **Adaptive Speed** | Automatically slows down when the target app can't keep up, speeds back up when it can |
| **Line-by-Line Delay** | Extra pause after newlines (0–2000ms) — useful for IPMI/terminal environments that need time to process each line |
| **Countdown Timer** | Configurable delay (0–10s) before typing starts so you can focus the target window |
| **Typing Preview** | Optional preview window showing text stats, character count, and estimated time before typing begins |
| **Progress Overlay** | Floating HUD during typing showing progress bar, character counter, and "Press Esc to cancel" |
| **Completion Notification** | macOS notification when typing finishes — useful when you switch away during long pastes |

### OCR

| Feature | Description |
|---------|-------------|
| **Screen Region OCR** | Drag to select any area on screen — PasteJack extracts text using Apple's Vision framework (on-device, no cloud) |
| **Multi-Region OCR** | Select multiple screen regions in one session — results are concatenated with separators |
| **Language Detection** | Automatically detects the language of recognized text and displays it as a badge |
| **Preferred Language** | Set a preferred OCR language for better recognition accuracy |
| **OCR History** | Keeps the last 20 OCR results for quick re-use |

### Productivity

| Feature | Description |
|---------|-------------|
| **Snippet Library** | Save, organize, and search frequently-typed text snippets — type any snippet with one click |
| **Typing History** | Remembers your last 10 typing sessions (auto-purges after 24 hours) |
| **Custom Hotkeys** | Record your own key combinations for all three actions in Settings |
| **Three Global Hotkeys** | Paste (⌃⇧V), OCR (⌃⇧C), Type Selected (⌃⇧T) — all customizable |

### Security & Privacy

| Feature | Description |
|---------|-------------|
| **Sensitive Content Detection** | Warns before typing if your clipboard contains API keys, private keys, JWT tokens, AWS credentials, or high-entropy strings |
| **100% Offline** | No network calls, no telemetry, no analytics, no cloud services |
| **No Keylogging** | PasteJack only sends keystrokes — it never reads or records what you type |
| **Menu Bar Only** | No Dock icon, no window clutter — lives quietly in your menu bar |

### Appearance

| Feature | Description |
|---------|-------------|
| **Dark / Light Mode** | Override system appearance per-app (System, Dark, or Light) |
| **Launch at Login** | Start automatically when you log in (via SMAppService) |

---

## Installation

### Homebrew (recommended)

```bash
brew tap wollux/tap
brew install --cask pastejack
```

### Manual

1. Download the latest `.dmg` from [Releases](https://github.com/wollux/PasteJack/releases)
2. Drag **PasteJack.app** to Applications
3. Launch PasteJack
4. Grant **Accessibility** and **Screen Recording** permissions when prompted

---

## Usage

### Paste as Keystrokes

1. Copy text to your clipboard (`Cmd+C`)
2. Click into the target application (IPMI console, VM, paste-blocked form, etc.)
3. Press **Ctrl+Shift+V**
4. Wait for the countdown (default: 3 seconds)
5. PasteJack types your clipboard contents character by character

### Copy from Screen (OCR)

1. Press **Ctrl+Shift+C**
2. Drag to select a screen region
3. PasteJack extracts text via OCR (Apple Vision, fully on-device)
4. Edit the recognized text if needed
5. Click **Copy** to clipboard, or **Type It** to type it directly

### Type Selected Text

1. Select text in any application
2. Press **Ctrl+Shift+T**
3. PasteJack copies the selection, then types it into the previously focused window

### Multi-Region OCR

1. Open the menu bar → click **Multi-Region OCR**
2. Drag to select the first region
3. Click to add more regions — press **Enter** to finish
4. All regions are OCR'd and concatenated

### Snippet Library

1. Open the menu bar → click **Snippet Library...**
2. Create snippets with a name and text body
3. Click **Type It** to type any snippet into the focused app
4. Search and organize your frequently-used text

---

## Settings

PasteJack provides granular control over every aspect of its behavior. All settings include an info tooltip (ℹ) explaining what they do.

### Typing

| Setting | Default | Range | Description |
|---------|---------|-------|-------------|
| Speed | 20ms | 5–200ms | Delay between keystrokes. Increase for slow targets |
| Countdown | 3s | 0–10s | Seconds before typing starts |
| Adaptive Speed | Off | — | Auto-slow when target app can't keep up |
| Line Delay | 0ms | 0–2000ms | Extra pause after each newline |
| Max Characters | 10,000 | — | Safety limit to prevent accidental large pastes |

### Behavior

| Setting | Default | Description |
|---------|---------|-------------|
| Launch at Login | Off | Start PasteJack when you log in |
| Play Sound | On | Glass sound effect on completion |
| Show Progress | On | Update menu bar icon during typing |
| Auto-close OCR | Off | Automatically close OCR result window |
| Notifications | On | macOS notification on typing completion |
| Sensitive Warn | On | Alert when clipboard contains secrets |
| Typing Preview | Off | Show preview window before typing starts |
| Appearance | System | Override: System / Dark / Light |

### Hotkeys

| Action | Default | Customizable |
|--------|---------|:------------:|
| Paste as Keystrokes | ⌃⇧V | Yes |
| Copy from Screen (OCR) | ⌃⇧C | Yes |
| Type Selected Text | ⌃⇧T | Yes |

All hotkeys can be re-recorded in Settings using the built-in hotkey recorder.

---

## Permissions

PasteJack requires two macOS permissions:

| Permission | Purpose | Required For |
|-----------|---------|-------------|
| **Accessibility** | Simulate keystrokes via CGEvent | All typing features |
| **Screen Recording** | Capture screen regions for OCR | OCR features only |

Grant both in **System Settings → Privacy & Security**. PasteJack provides a guided onboarding flow on first launch.

---

## How It Works

### Keystroke Simulation

PasteJack uses `CGEvent` (Core Graphics Event) to inject keyboard events at the OS level:

```
Clipboard text → Character loop → CGEvent.keyboardSetUnicodeString() → keyDown/keyUp → Target app
```

For printable characters, `keyboardSetUnicodeString()` sends the Unicode value directly — no keyboard layout mapping needed. Control characters (Return, Tab, Escape, Backspace) are sent as virtual keycodes since they have no printable representation.

### Adaptive Speed

When enabled, PasteJack measures the time each `CGEvent.post()` takes. If events start queuing (post takes longer than expected), it automatically increases the delay. After a window of successful fast keystrokes, it gradually recovers to the base speed.

### OCR

The OCR feature uses Apple's Vision framework (`VNRecognizeTextRequest`) for fully on-device text recognition. No data leaves your Mac. Language detection uses `NLLanguageRecognizer` from the Natural Language framework.

### Sensitive Content Detection

Before typing, PasteJack scans the clipboard for:

- **API keys** — OpenAI (`sk-`), GitHub (`ghp_`, `gho_`, `ghs_`), Stripe (`pk_`, `rk_`), AWS (`AKIA`), Slack (`xoxb-`, `xoxp-`)
- **Private keys** — `-----BEGIN PRIVATE KEY-----`
- **JWT tokens** — `eyJ...` pattern
- **High-entropy strings** — Shannon entropy > 4.5 on strings ≥ 24 characters (catches random passwords and secrets)

If a match is found, PasteJack shows a warning dialog before proceeding.

---

## Recommended Speeds

| Target Environment | Suggested Delay | Line Delay |
|---|---|---|
| Local apps (Terminal, browser) | 5–20ms | 0ms |
| RDP (local network) | 20–30ms | 0ms |
| RDP (over WAN / VPN) | 30–50ms | 50–100ms |
| IPMI / iLO / iDRAC | 50–100ms | 200–500ms |
| Very slow consoles | 100–200ms | 500–2000ms |

Start with the defaults (20ms) and increase if characters are dropped.

---

## Architecture

```
PasteJack/
├── Sources/PasteJack/
│   ├── App/
│   │   ├── PasteJackApp.swift              # @main entry point, menu bar only
│   │   └── AppDelegate.swift               # Hotkeys, windows, session management
│   ├── Core/
│   │   ├── KeystrokeEngine.swift           # CGEvent keystroke simulation
│   │   ├── TypingSession.swift             # Session state machine (idle → countdown → typing → done)
│   │   ├── ClipboardReader.swift           # NSPasteboard reading with type detection
│   │   ├── KeyMapping.swift                # Control character → virtual keycode mapping
│   │   ├── OCREngine.swift                 # Vision framework OCR with language detection
│   │   ├── ScreenCapture.swift             # CGWindowListCreateImage screen capture
│   │   ├── OCRHistory.swift                # Persistent OCR result history (last 20)
│   │   ├── TypingHistory.swift             # Persistent typing session history (last 10)
│   │   └── SnippetStore.swift              # Snippet library CRUD with JSON persistence
│   ├── UI/
│   │   ├── MenuBarView.swift               # Status menu with real-time state
│   │   ├── SettingsView.swift              # Settings window with info tooltips
│   │   ├── StatusIndicator.swift           # Menu bar icon state management
│   │   ├── OCRResultView.swift             # Editable OCR result with language badges
│   │   ├── ScreenSelectionOverlay.swift    # Drag-to-select overlay (single + multi-region)
│   │   ├── SnippetLibraryView.swift        # Snippet library with search and editor
│   │   ├── HotkeyRecorderView.swift        # Interactive hotkey recorder component
│   │   ├── TypingOverlayView.swift         # Floating progress HUD
│   │   ├── TypingPreviewView.swift         # Pre-typing text preview with stats
│   │   └── AccessibilityOnboardingView.swift # Guided permission setup
│   ├── Settings/
│   │   ├── UserSettings.swift              # @AppStorage wrapper for all preferences
│   │   └── HotkeyManager.swift             # Carbon global hotkey registration
│   └── Utilities/
│       ├── Constants.swift                 # App-wide defaults and limits
│       ├── AccessibilityChecker.swift      # Accessibility permission check
│       ├── ScreenRecordingChecker.swift    # Screen Recording permission check
│       ├── SensitiveDetector.swift         # Regex + entropy-based secret detection
│       ├── KeyboardLayoutDetector.swift    # Input source detection
│       └── DevBundleHelper.swift           # Dev environment bundle wrapper
├── Tests/PasteJackTests/
│   ├── KeyMappingTests.swift               # Control character mapping tests
│   ├── ClipboardReaderTests.swift          # Clipboard parsing tests
│   ├── TypingSessionTests.swift            # Session state machine tests
│   └── OCREngineTests.swift                # OCR recognition tests
├── Scripts/
│   ├── build.sh                            # Build universal binary + app bundle
│   ├── create-dmg.sh                       # Package into DMG
│   ├── notarize.sh                         # Apple notarization workflow
│   └── bump-version.sh                     # Version bump + git tag
└── Distribution/
    └── Casks/
        └── pastejack.rb                    # Homebrew Cask formula
```

---

## Tech Stack

- **Language:** Swift 5.9+
- **UI:** SwiftUI (macOS 14 Sonoma minimum)
- **Build System:** Swift Package Manager — no Xcode project file
- **Dependencies:** None — pure Apple frameworks only
- **Frameworks used:** CoreGraphics, Carbon, AppKit, SwiftUI, Vision, NaturalLanguage, UserNotifications, ServiceManagement
- **Distribution:** Homebrew Cask (notarized DMG)

---

## Building from Source

```bash
git clone https://github.com/wollux/PasteJack.git
cd PasteJack

# Debug build + run
swift build
swift run

# Run tests
swift test

# Release build (universal binary: Apple Silicon + Intel)
swift build -c release --arch arm64 --arch x86_64

# Create app bundle + DMG
./Scripts/build.sh
./Scripts/create-dmg.sh
```

### Requirements

- macOS 14 (Sonoma) or later
- Xcode Command Line Tools or Xcode 15+
- Apple Silicon or Intel Mac

---

## FAQ

**Q: Why not just use AppleScript `keystroke`?**
A: AppleScript's `keystroke` command is slower, unreliable with special characters, and requires different permission handling. CGEvent is the correct low-level API for this.

**Q: Does it work with non-English text?**
A: Yes. `keyboardSetUnicodeString()` handles any Unicode character — Chinese, Japanese, Korean, Arabic, Cyrillic, emoji, and more.

**Q: Will it work in my IPMI console?**
A: Almost certainly. Increase the speed to 50–100ms and enable a line delay of 200–500ms for best results with slow IPMI/iLO/iDRAC consoles.

**Q: Is my clipboard data sent anywhere?**
A: No. PasteJack runs 100% offline. No network calls, no telemetry, no cloud services. Your clipboard data never leaves your Mac.

**Q: Can I use it to auto-type passwords?**
A: You can, but PasteJack will warn you if it detects sensitive content like API keys or high-entropy strings. Use at your own risk and make sure the correct window is focused.

**Q: Why does it need Accessibility permission?**
A: macOS requires Accessibility permission for any app that simulates keyboard input via CGEvent. This is an OS-level security requirement.

**Q: Why does it need Screen Recording permission?**
A: Only for the OCR feature. Screen Recording permission allows PasteJack to capture the screen region you select for text extraction.

---

## License

Free to use, copy, modify, and distribute. No warranty. See [LICENSE](LICENSE) for details.

Copyright (c) 2026 Wolfgang Vieregg
