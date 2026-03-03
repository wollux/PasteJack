# CLAUDE.md — PasteJack

## Project Overview

**PasteJack** is a native macOS menu bar utility that simulates keyboard input from clipboard contents. It solves the problem of pasting text into environments that block clipboard access: IPMI/iLO/iDRAC consoles, RDP sessions without clipboard redirect, VMs without guest tools, and web forms that block `onpaste`.

The app reads the clipboard and sends each character as a simulated keystroke via the macOS Accessibility API (`CGEvent`). For the target application, it looks like the user is physically typing.

## Tech Stack

- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI (macOS 14+ Sonoma minimum deployment target)
- **Build System:** Swift Package Manager (SPM) — no Xcode project file
- **Distribution:** Homebrew Cask (direct download, notarized DMG)
- **No dependencies** — pure Apple frameworks only

## Architecture

```
PasteJack/
├── CLAUDE.md
├── Package.swift
├── Sources/
│   └── PasteJack/
│       ├── App/
│       │   ├── PasteJackApp.swift           # @main, NSApplication setup, menu bar only (no Dock icon)
│       │   └── AppDelegate.swift            # NSApplicationDelegate, global hotkey registration
│       ├── Core/
│       │   ├── KeystrokeEngine.swift        # CGEvent-based keystroke simulation
│       │   ├── ClipboardReader.swift        # NSPasteboard reading with type detection
│       │   ├── KeyMapping.swift             # Unicode char → virtual keycode + modifiers mapping
│       │   └── TypingSession.swift          # Orchestrates a paste-as-keystrokes session
│       ├── UI/
│       │   ├── MenuBarView.swift            # NSStatusItem + SwiftUI menu
│       │   ├── SettingsView.swift           # Preferences window (SwiftUI)
│       │   └── StatusIndicator.swift        # Menu bar icon state (idle/typing/error)
│       ├── Settings/
│       │   ├── UserSettings.swift           # @AppStorage wrapper for all preferences
│       │   └── HotkeyManager.swift          # Global hotkey registration (Carbon or CGEvent tap)
│       └── Utilities/
│           ├── AccessibilityChecker.swift   # Check and prompt for Accessibility permission
│           ├── KeyboardLayoutDetector.swift  # Detect current input source (DE, US, etc.)
│           └── Constants.swift              # App-wide constants
├── Resources/
│   ├── Assets.xcassets/                     # App icon, menu bar icons (template images)
│   └── PasteJack.entitlements               # Hardened Runtime entitlements
├── Scripts/
│   ├── build.sh                             # Build release binary
│   ├── create-dmg.sh                        # Package into DMG
│   ├── notarize.sh                          # Apple notarization workflow
│   └── bump-version.sh                      # Version bump + git tag
├── Distribution/
│   └── Casks/
│       └── pastejack.rb                     # Homebrew Cask formula
├── Tests/
│   └── PasteJackTests/
│       ├── KeyMappingTests.swift            # Char→keycode mapping tests
│       ├── ClipboardReaderTests.swift       # Clipboard parsing tests
│       └── TypingSessionTests.swift         # Session orchestration tests
├── LICENSE                                  # MIT
└── README.md
```

## Core Implementation Details

### KeystrokeEngine.swift

This is the heart of the app. It uses `CGEvent` to simulate keystrokes.

```swift
import CoreGraphics
import Carbon.HIToolbox

final class KeystrokeEngine {
    
    private let eventSource: CGEventSource?
    
    init() {
        self.eventSource = CGEventSource(stateID: .hidSystemState)
    }
    
    /// Type a single Unicode character using CGEvent.
    /// Uses keyboardSetUnicodeString which handles all Unicode chars
    /// regardless of keyboard layout — this is the KEY insight.
    func typeCharacter(_ char: Character, delay: UInt32) {
        let utf16 = Array(String(char).utf16)
        
        // Create a keyDown event with a dummy keycode (0)
        guard let keyDown = CGEvent(keyboardEventSource: eventSource, virtualKey: 0, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: eventSource, virtualKey: 0, keyDown: false) else {
            return
        }
        
        // Set the Unicode string — this overrides the virtual keycode
        keyDown.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)
        keyUp.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)
        
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
        
        usleep(delay)
    }
    
    /// Special handling for control characters (Return, Tab, Escape, etc.)
    func typeControlCharacter(_ keyCode: CGKeyCode, modifiers: CGEventFlags = [], delay: UInt32) {
        guard let keyDown = CGEvent(keyboardEventSource: eventSource, virtualKey: keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: eventSource, virtualKey: keyCode, keyDown: false) else {
            return
        }
        
        keyDown.flags = modifiers
        keyUp.flags = modifiers
        
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
        
        usleep(delay)
    }
}
```

**Critical design decision:** Use `keyboardSetUnicodeString()` instead of virtual keycode mapping. This bypasses the need to know the keyboard layout for printable characters. Virtual keycodes are only needed for control keys (Return, Tab, Backspace, arrow keys, etc.).

### Control character mapping

```swift
// KeyMapping.swift
enum ControlCharMapping {
    static let map: [Character: (keyCode: CGKeyCode, modifiers: CGEventFlags)] = [
        "\n": (CGKeyCode(kVK_Return), []),
        "\r": (CGKeyCode(kVK_Return), []),
        "\t": (CGKeyCode(kVK_Tab), []),
        "\u{1B}": (CGKeyCode(kVK_Escape), []),  // ESC
        "\u{7F}": (CGKeyCode(kVK_Delete), []),   // Backspace
    ]
    
    static func isControlCharacter(_ char: Character) -> Bool {
        if let scalar = char.unicodeScalars.first {
            return scalar.value < 32 || scalar.value == 127
        }
        return false
    }
}
```

### TypingSession.swift

Orchestrates a full typing session with progress, cancellation, and error handling.

```swift
import Combine

@MainActor
final class TypingSession: ObservableObject {
    
    enum State {
        case idle
        case countdown(remaining: Int)  // Pre-type delay
        case typing(progress: Double, current: Int, total: Int)
        case completed
        case cancelled
        case error(String)
    }
    
    @Published var state: State = .idle
    
    private let engine = KeystrokeEngine()
    private var task: Task<Void, Never>?
    
    /// Start typing the given text with configurable delay per character.
    func start(text: String, delayMicroseconds: UInt32, countdownSeconds: Int) {
        let characters = Array(text)
        let total = characters.count
        
        task = Task {
            // Countdown phase — gives user time to focus the target window
            for i in stride(from: countdownSeconds, through: 1, by: -1) {
                state = .countdown(remaining: i)
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { state = .cancelled; return }
            }
            
            // Typing phase
            for (index, char) in characters.enumerated() {
                if Task.isCancelled { state = .cancelled; return }
                
                state = .typing(
                    progress: Double(index + 1) / Double(total),
                    current: index + 1,
                    total: total
                )
                
                if let control = ControlCharMapping.map[char] {
                    engine.typeControlCharacter(control.keyCode, modifiers: control.modifiers, delay: delayMicroseconds)
                } else {
                    engine.typeCharacter(char, delay: delayMicroseconds)
                }
            }
            
            state = .completed
        }
    }
    
    func cancel() {
        task?.cancel()
    }
}
```

### Accessibility Permission Check

```swift
import ApplicationServices

enum AccessibilityChecker {
    
    /// Check if the app has Accessibility permission.
    static var hasPermission: Bool {
        AXIsProcessTrusted()
    }
    
    /// Prompt the user to grant Accessibility permission.
    /// Opens System Settings directly to the Accessibility pane.
    static func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
}
```

### Global Hotkey (Carbon-based, most reliable)

```swift
import Carbon.HIToolbox

final class HotkeyManager {
    
    typealias Handler = () -> Void
    
    private var hotKeyRef: EventHotKeyRef?
    private var handler: Handler?
    
    // Carbon event handler stored as class property to prevent deallocation
    private var eventHandlerRef: EventHandlerRef?
    
    /// Register a global hotkey. Default: Ctrl+Shift+V
    func register(
        keyCode: UInt32 = UInt32(kVK_ANSI_V),
        modifiers: UInt32 = UInt32(controlKey | shiftKey),
        handler: @escaping Handler
    ) {
        self.handler = handler
        
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        
        // Install handler
        let handlerBlock: EventHandlerUPP = { _, event, userData -> OSStatus in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }
            let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
            manager.handler?()
            return noErr
        }
        
        InstallEventHandler(
            GetApplicationEventTarget(),
            handlerBlock,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )
        
        // Register hotkey
        var hotkeyID = EventHotKeyID(signature: OSType(0x504A), id: 1) // "PJ"
        RegisterEventHotKey(keyCode, modifiers, hotkeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }
    
    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
    }
    
    deinit {
        unregister()
    }
}
```

### User Settings

```swift
import SwiftUI

final class UserSettings: ObservableObject {
    
    static let shared = UserSettings()
    
    /// Delay between keystrokes in milliseconds
    @AppStorage("keystrokeDelayMs") var keystrokeDelayMs: Double = 20
    
    /// Countdown seconds before typing starts
    @AppStorage("countdownSeconds") var countdownSeconds: Int = 3
    
    /// Whether to launch at login
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false
    
    /// Play sound on completion
    @AppStorage("playSoundOnComplete") var playSoundOnComplete: Bool = true
    
    /// Show typing progress in menu bar
    @AppStorage("showProgress") var showProgress: Bool = true
    
    /// Maximum characters to type (safety limit)
    @AppStorage("maxCharacters") var maxCharacters: Int = 10000
    
    /// Computed: delay in microseconds for usleep()
    var delayMicroseconds: UInt32 {
        UInt32(keystrokeDelayMs * 1000)
    }
}
```

### App Entry Point (Menu Bar Only, No Dock Icon)

```swift
import SwiftUI

@main
struct PasteJackApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Use Settings scene for the preferences window
        Settings {
            SettingsView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var statusItem: NSStatusItem!
    private let hotkeyManager = HotkeyManager()
    private let session = TypingSession()
    private var popover: NSPopover?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide Dock icon
        NSApp.setActivationPolicy(.accessory)
        
        // Setup menu bar
        setupStatusItem()
        
        // Check Accessibility permission
        if !AccessibilityChecker.hasPermission {
            AccessibilityChecker.requestPermission()
        }
        
        // Register global hotkey (Ctrl+Shift+V)
        hotkeyManager.register { [weak self] in
            self?.handleHotkey()
        }
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            // Use SF Symbol as template image
            button.image = NSImage(systemSymbolName: "keyboard.badge.ellipsis", accessibilityDescription: "PasteJack")
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Paste as Keystrokes (⌃⇧V)", action: #selector(handleHotkey), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "About PasteJack", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit PasteJack", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    @objc private func handleHotkey() {
        guard AccessibilityChecker.hasPermission else {
            AccessibilityChecker.requestPermission()
            return
        }
        
        guard let text = NSPasteboard.general.string(forType: .string), !text.isEmpty else {
            return
        }
        
        let settings = UserSettings.shared
        
        guard text.count <= settings.maxCharacters else {
            return
        }
        
        session.start(
            text: text,
            delayMicroseconds: settings.delayMicroseconds,
            countdownSeconds: settings.countdownSeconds
        )
    }
    
    @objc private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func showAbout() {
        NSApp.orderFrontStandardAboutPanel(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
```

### Settings View

```swift
import SwiftUI

struct SettingsView: View {
    
    @ObservedObject private var settings = UserSettings.shared
    @State private var accessibilityGranted = AccessibilityChecker.hasPermission
    
    var body: some View {
        Form {
            Section("Typing") {
                HStack {
                    Text("Speed")
                    Slider(value: $settings.keystrokeDelayMs, in: 5...200, step: 5) {
                        Text("Keystroke Delay")
                    }
                    Text("\(Int(settings.keystrokeDelayMs))ms")
                        .monospacedDigit()
                        .frame(width: 50, alignment: .trailing)
                }
                
                Stepper("Countdown: \(settings.countdownSeconds)s", value: $settings.countdownSeconds, in: 0...10)
                
                TextField("Max characters", value: $settings.maxCharacters, format: .number)
            }
            
            Section("Behavior") {
                Toggle("Launch at Login", isOn: $settings.launchAtLogin)
                Toggle("Play sound on completion", isOn: $settings.playSoundOnComplete)
                Toggle("Show progress in menu bar", isOn: $settings.showProgress)
            }
            
            Section("Hotkey") {
                Text("⌃⇧V (Ctrl+Shift+V)")
                    .foregroundStyle(.secondary)
                // TODO: Custom hotkey recorder
            }
            
            Section("Permissions") {
                HStack {
                    Image(systemName: accessibilityGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(accessibilityGranted ? .green : .orange)
                    Text(accessibilityGranted ? "Accessibility: Granted" : "Accessibility: Not Granted")
                    Spacer()
                    if !accessibilityGranted {
                        Button("Grant Access") {
                            AccessibilityChecker.requestPermission()
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 350)
        .onAppear {
            accessibilityGranted = AccessibilityChecker.hasPermission
        }
    }
}
```

## Package.swift

```swift
// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "PasteJack",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "PasteJack",
            path: "Sources/PasteJack",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "PasteJackTests",
            dependencies: ["PasteJack"],
            path: "Tests/PasteJackTests"
        )
    ]
)
```

## Entitlements (PasteJack.entitlements)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
    <key>com.apple.security.cs.disable-library-validation</key>
    <false/>
    <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
    <false/>
    <key>com.apple.security.cs.allow-jit</key>
    <false/>
</dict>
</plist>
```

**Important:** Sandbox is explicitly `false`. Hardened Runtime is enabled via the build flags, not the entitlements. No special entitlements needed — Accessibility permission is granted at runtime via TCC.

## Build & Distribution Scripts

### Scripts/build.sh

```bash
#!/bin/bash
set -euo pipefail

APP_NAME="PasteJack"
BUILD_DIR=".build/release"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"
VERSION=$(git describe --tags --always 2>/dev/null || echo "0.1.0")

echo "==> Building ${APP_NAME} v${VERSION}..."

# Universal binary (Apple Silicon + Intel)
swift build -c release \
    --arch arm64 \
    --arch x86_64

BINARY="${BUILD_DIR}/${APP_NAME}"

echo "==> Creating app bundle..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

cp "${BINARY}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

cat > "${APP_BUNDLE}/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.pastejack.app</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 PasteJack. MIT License.</string>
</dict>
</plist>
EOF

cp Resources/PasteJack.entitlements "${APP_BUNDLE}/Contents/Resources/"

echo "==> Signing with hardened runtime..."
codesign --force --deep --options runtime \
    --entitlements Resources/PasteJack.entitlements \
    --sign "Developer ID Application: YOUR_NAME (TEAM_ID)" \
    "${APP_BUNDLE}"

echo "==> Build complete: ${APP_BUNDLE}"
```

### Scripts/create-dmg.sh

```bash
#!/bin/bash
set -euo pipefail

APP_NAME="PasteJack"
VERSION=$(git describe --tags --always 2>/dev/null || echo "0.1.0")
APP_BUNDLE=".build/release/${APP_NAME}.app"
DMG_DIR=".build/dmg"
DMG_FILE=".build/${APP_NAME}-${VERSION}.dmg"

echo "==> Creating DMG..."

rm -rf "${DMG_DIR}"
mkdir -p "${DMG_DIR}"
cp -R "${APP_BUNDLE}" "${DMG_DIR}/"
ln -s /Applications "${DMG_DIR}/Applications"

create-dmg \
    --volname "${APP_NAME}" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "${APP_NAME}.app" 175 190 \
    --icon "Applications" 425 190 \
    --hide-extension "${APP_NAME}.app" \
    --app-drop-link 425 190 \
    "${DMG_FILE}" \
    "${DMG_DIR}"

echo "==> DMG created: ${DMG_FILE}"
```

### Scripts/notarize.sh

```bash
#!/bin/bash
set -euo pipefail

APP_NAME="PasteJack"
VERSION=$(git describe --tags --always 2>/dev/null || echo "0.1.0")
DMG_FILE=".build/${APP_NAME}-${VERSION}.dmg"
APPLE_ID="your@apple-id.com"
TEAM_ID="YOUR_TEAM_ID"
APP_PASSWORD="@keychain:AC_PASSWORD"

echo "==> Submitting ${DMG_FILE} for notarization..."

xcrun notarytool submit "${DMG_FILE}" \
    --apple-id "${APPLE_ID}" \
    --team-id "${TEAM_ID}" \
    --password "${APP_PASSWORD}" \
    --wait

echo "==> Stapling notarization ticket..."
xcrun stapler staple "${DMG_FILE}"

echo "==> Verifying..."
xcrun stapler validate "${DMG_FILE}"
spctl --assess --type open --context context:primary-signature "${DMG_FILE}"

echo "==> Notarization complete!"
```

## Homebrew Cask Distribution

### Distribution/Casks/pastejack.rb

```ruby
cask "pastejack" do
  version "0.1.0"
  sha256 "PLACEHOLDER_SHA256"

  url "https://github.com/YOURUSER/PasteJack/releases/download/v#{version}/PasteJack-#{version}.dmg"
  name "PasteJack"
  desc "Paste clipboard contents as simulated keystrokes — bypass paste-blocking"
  homepage "https://github.com/YOURUSER/PasteJack"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :sonoma"

  app "PasteJack.app"

  zap trash: [
    "~/Library/Preferences/com.pastejack.app.plist",
    "~/Library/Application Support/PasteJack",
  ]

  caveats <<~EOS
    PasteJack requires Accessibility permission to simulate keystrokes.

    After installation, go to:
      System Settings → Privacy & Security → Accessibility
    and enable PasteJack.

    Default hotkey: Ctrl+Shift+V
  EOS
end
```

### Homebrew Distribution Steps

**Option A: Own Homebrew Tap (recommended for indie apps)**

```bash
# 1. Create a GitHub repo: homebrew-tap
# Repo structure:
#   homebrew-tap/
#   └── Casks/
#       └── pastejack.rb

# 2. Users install via:
brew tap youruser/tap
brew install --cask pastejack

# 3. To update: push new version of pastejack.rb to your tap repo
```

**Option B: Submit to homebrew-cask (official, requires popularity)**

```bash
# Only after the app has enough traction
# Fork homebrew/homebrew-cask, add Cask, submit PR
# Requires: notable user base, active maintenance
```

### GitHub Release Automation (.github/workflows/release.yml)

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Build Universal Binary
        run: swift build -c release --arch arm64 --arch x86_64

      - name: Create App Bundle
        run: ./Scripts/build.sh

      - name: Create DMG
        run: |
          brew install create-dmg
          ./Scripts/create-dmg.sh

      - name: Import Signing Certificate
        env:
          CERTIFICATE_BASE64: ${{ secrets.DEVELOPER_ID_CERT }}
          CERTIFICATE_PASSWORD: ${{ secrets.CERT_PASSWORD }}
        run: |
          echo "$CERTIFICATE_BASE64" | base64 --decode > certificate.p12
          security create-keychain -p "" build.keychain
          security import certificate.p12 -k build.keychain -P "$CERTIFICATE_PASSWORD" -T /usr/bin/codesign
          security set-key-partition-list -S apple-tool:,apple: -k "" build.keychain
          security list-keychains -d user -s build.keychain

      - name: Notarize
        env:
          APPLE_ID: ${{ secrets.APPLE_ID }}
          TEAM_ID: ${{ secrets.TEAM_ID }}
          AC_PASSWORD: ${{ secrets.AC_PASSWORD }}
        run: ./Scripts/notarize.sh

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          files: .build/PasteJack-*.dmg
          generate_release_notes: true
```

## Key Implementation Notes

### Why `keyboardSetUnicodeString` over virtual keycode mapping

Most clipboard-as-keystrokes tools fail because they try to map each character to a virtual keycode. This breaks on:
- Non-US keyboard layouts (DE has Y/Z swapped, different symbol positions)
- Accented characters (ü, ö, ä, é, ñ)
- Special symbols that require dead keys

`CGEvent.keyboardSetUnicodeString()` sends the Unicode character directly, bypassing the keyboard layout entirely. The only exceptions are control characters (Return, Tab, etc.) which must use virtual keycodes because they don't have a printable Unicode representation.

### Timing considerations

- **Default delay: 20ms** — works for most local apps and fast networks
- **IPMI/iLO/iDRAC: 50-100ms** — these consoles are slow and drop chars at higher speeds
- **RDP over WAN: 30-50ms** — network latency adds to the delay
- **User should have a "Speed" slider** in settings to adjust
- **Adaptive mode (future):** Start fast, slow down if the target app can't keep up. This is a v2 feature.

### Cancellation

The user MUST be able to cancel mid-typing:
- **Press Escape** during typing → cancel immediately (register another CGEvent tap to monitor keyDown for Escape)
- **Click the menu bar icon** → cancel
- Critical for security — if someone accidentally starts typing a password in the wrong window

### Safety features

- **Max character limit** (default 10,000) — prevent typing War and Peace by accident
- **Countdown** (default 3s) — gives user time to focus the correct target window
- **Clipboard content preview** — show first/last 20 chars in the menu bar tooltip before typing
- **Visual indicator** — menu bar icon changes during typing (pulsing keyboard icon)

### Things NOT to do

- Do NOT use AppleScript `keystroke` — slow, unreliable with special chars, different permissions
- Do NOT use `NSEvent.addGlobalMonitorForEvents` for the hotkey — doesn't work for all apps, use Carbon `RegisterEventHotKey`
- Do NOT try to make it work in a sandbox — it won't
- Do NOT support macOS < 14 — not worth the SwiftUI compatibility headaches
- Do NOT add a Dock icon — menu bar utility, `LSUIElement = true`

## Testing Strategy

### Unit Tests

- `KeyMappingTests`: Verify control character detection and mapping
- `ClipboardReaderTests`: Test with various pasteboard types (string, RTF, etc.)
- `TypingSessionTests`: Test state machine transitions (idle → countdown → typing → completed/cancelled)

### Manual Test Matrix

| Target | Delay | Characters | Expected |
|--------|-------|-----------|----------|
| Terminal.app | 20ms | ASCII only | Clean output |
| Terminal.app | 20ms | `äöü@€{}[]\\|~` | All correct |
| UTM VM (no tools) | 50ms | Mixed text | Clean output |
| Safari form (paste blocked) | 20ms | Password | Should work |
| IPMI console (via Safari/Chrome) | 100ms | Long SSH key | All chars correct |

### Accessibility Permission Test

- Fresh install → app prompts for permission → user grants → hotkey works
- Permission revoked → app detects and shows warning
- App launched without permission → graceful degradation (menu bar shows warning icon)

## Version Roadmap

### v0.1.0 (MVP)

- [x] Menu bar app, no Dock icon
- [x] Global hotkey (Ctrl+Shift+V)
- [x] Type clipboard as keystrokes via CGEvent
- [x] Configurable delay (speed slider)
- [x] Countdown before typing
- [x] Escape to cancel
- [x] Accessibility permission check and prompt
- [x] Settings window
- [x] DMG distribution
- [x] Homebrew Cask

### v0.2.0

- [ ] Custom hotkey recorder
- [ ] Launch at Login (via SMAppService)
- [ ] Auto-update (Sparkle framework)
- [ ] Typing history (last 5 pastes, opt-in)
- [ ] Menu bar progress indicator during typing

### v0.3.0

- [ ] Adaptive speed mode
- [ ] Snippet library (save frequently typed text)
- [ ] Multiple keyboard layout awareness for edge cases
- [ ] Localization (DE, EN)

## Code Style

- All comments in English
- Swift naming conventions (camelCase properties, PascalCase types)
- No force unwraps except in `fatalError` paths
- Prefer `guard` over nested `if let`
- Use `@MainActor` for all UI-touching code
- Async/await over completion handlers

## Bundle Identifier

`com.pastejack.app`

Change this to your own reverse-domain before shipping.

## License

MIT — keep it simple, maximize adoption.
