# PasteJack

**Paste anywhere. Even where you can't.**

A native macOS menu bar utility that simulates keyboard input from your clipboard. Bypass paste-blocking in IPMI/iLO/iDRAC consoles, RDP sessions, VMs without guest tools, and web forms that block `onpaste`.

## Features

- **Paste as Keystrokes** — Types clipboard contents character by character via simulated keystrokes (Ctrl+Shift+V)
- **Copy from Screen (OCR)** — Select any screen region, extract text via OCR, edit it, and type it into any app (Ctrl+Shift+C)
- **Works everywhere** — IPMI/iLO/iDRAC consoles, RDP without clipboard redirect, VMs without guest tools, paste-blocked web forms
- **Any keyboard layout** — Uses `CGEvent.keyboardSetUnicodeString()` to send Unicode directly, works with US, German, French, and any other layout
- **Special characters** — Handles `@`, `€`, `{}`, `[]`, `\`, `~`, accented chars (`ü`, `ö`, `ä`, `é`, `ñ`) without layout-specific mapping
- **Configurable speed** — 5ms to 200ms delay per keystroke, adjustable for slow targets like IPMI consoles
- **Countdown timer** — Configurable delay before typing starts so you can focus the target window
- **Cancel anytime** — Press Escape or click the menu bar icon to stop mid-typing
- **Privacy first** — Runs 100% offline, no telemetry, no keylogging, no background activity
- **Menu bar only** — No Dock icon, lives quietly in your menu bar

## Installation

### Homebrew (recommended)

```bash
brew tap wollux/tap
brew install --cask pastejack
```

### Manual

1. Download the latest `.dmg` from [Releases](https://github.com/wollux/PasteJack/releases)
2. Drag PasteJack to Applications
3. Launch PasteJack
4. Grant Accessibility and Screen Recording permissions when prompted

## Usage

### Paste as Keystrokes

1. Copy text to your clipboard (Cmd+C)
2. Click into the target application (IPMI console, VM, paste-blocked form, etc.)
3. Press **Ctrl+Shift+V**
4. Wait for the countdown (default: 3s) to focus the right window
5. PasteJack types your clipboard contents character by character

### Copy from Screen (OCR)

1. Press **Ctrl+Shift+C**
2. Drag to select a screen region
3. PasteJack extracts text via OCR (Apple Vision framework)
4. Edit the recognized text if needed
5. Click **Copy** to copy to clipboard, or **Type It** to type it directly into another app

## Settings

| Setting | Default | Description |
|---------|---------|-------------|
| Speed | 20ms | Delay between keystrokes. Increase for slow targets (IPMI: 50-100ms, RDP over WAN: 30-50ms) |
| Countdown | 3s | Seconds before typing starts. Gives you time to focus the target window |
| Max characters | 10,000 | Safety limit to prevent accidental large pastes |
| Play sound | On | Audio feedback when typing completes |
| Show progress | On | Menu bar icon changes during typing |
| Auto-close OCR | Off | Automatically close the OCR result window after a delay |

## Permissions

PasteJack requires two macOS permissions:

| Permission | Why |
|-----------|-----|
| **Accessibility** | Required to simulate keystrokes via CGEvent |
| **Screen Recording** | Required for the OCR "Copy from Screen" feature |

Grant both in **System Settings > Privacy & Security**. PasteJack prompts on first launch.

## Requirements

- macOS 14 (Sonoma) or later
- Apple Silicon or Intel Mac

## How It Works

PasteJack uses the macOS `CGEvent` API to simulate keystroke events at the OS level.

The key insight: `CGEvent.keyboardSetUnicodeString()` sends Unicode characters directly, bypassing the need for virtual keycode-to-character mapping. This is why PasteJack works with any keyboard layout and special characters — the target app receives the character itself, not a keycode that depends on layout.

Control characters (Return, Tab, Escape, Backspace) are sent as virtual keycodes since they don't have printable Unicode representations.

The OCR feature uses Apple's Vision framework (`VNRecognizeTextRequest`) for on-device text recognition — no cloud services involved.

## Why PasteJack?

Pasting text into remote consoles and restricted environments is a common pain point for sysadmins and developers:

- **IPMI/iLO/iDRAC** web consoles don't support clipboard
- **RDP** without clipboard redirection
- **VMs** without guest additions/tools
- **Web forms** that block the paste event with JavaScript
- **Secure terminals** that disable paste for security

PasteJack solves all of these by simulating keyboard input at the OS level.

## Building from Source

```bash
git clone https://github.com/wollux/PasteJack.git
cd PasteJack

swift build          # Debug build
swift run            # Run
swift test           # Test

# Release (universal binary)
swift build -c release --arch arm64 --arch x86_64
```

## License

Free to use, copy, modify, and distribute. No warranty. See [LICENSE](LICENSE) for details.

Copyright (c) 2026 Wolfgang Vieregg
