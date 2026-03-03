# PasteJack

A native macOS menu bar utility that pastes clipboard contents as simulated keystrokes. Bypass paste-blocking in IPMI/iLO/iDRAC consoles, RDP sessions, VMs without guest tools, and web forms that block `onpaste`.

## How It Works

PasteJack reads your clipboard and sends each character as a simulated keystroke via the macOS Accessibility API (`CGEvent`). To the target application, it looks like you're physically typing.

The key insight: `CGEvent.keyboardSetUnicodeString()` sends Unicode characters directly, bypassing the keyboard layout entirely. This means it works correctly with any keyboard layout (US, German, French, etc.) and handles special characters like `@`, `€`, `{}`, `[]`, and accented characters (`ü`, `ö`, `ä`, `é`) without layout-specific mapping.

## Installation

### Homebrew (recommended)

```bash
brew tap youruser/tap
brew install --cask pastejack
```

### Manual

1. Download the latest `.dmg` from [Releases](https://github.com/YOURUSER/PasteJack/releases)
2. Drag PasteJack to Applications
3. Launch PasteJack
4. Grant Accessibility permission when prompted

## Usage

1. Copy text to your clipboard (Cmd+C)
2. Click into the target application (IPMI console, VM, paste-blocked form, etc.)
3. Press **Ctrl+Shift+V** (or use the menu bar icon)
4. Wait for the countdown (default: 3 seconds) to focus the right window
5. PasteJack types your clipboard contents character by character

### Menu Bar

PasteJack lives in your menu bar. Click the keyboard icon to:
- Paste as Keystrokes
- Cancel an active typing session
- Open Settings
- Quit

## Settings

| Setting | Default | Description |
|---------|---------|-------------|
| Speed | 20ms | Delay between keystrokes. Increase for slow targets (IPMI: 50-100ms) |
| Countdown | 3s | Seconds before typing starts. Gives you time to focus the target window |
| Max characters | 10,000 | Safety limit to prevent accidental large pastes |
| Play sound | On | Audio feedback when typing completes |
| Show progress | On | Menu bar icon changes during typing |

## Requirements

- macOS 14 (Sonoma) or later
- Accessibility permission (System Settings > Privacy & Security > Accessibility)

## Building from Source

```bash
# Clone the repository
git clone https://github.com/YOURUSER/PasteJack.git
cd PasteJack

# Build (debug)
swift build

# Build (release, universal binary)
swift build -c release --arch arm64 --arch x86_64

# Run
swift run

# Test
swift test
```

## Why PasteJack?

Pasting text into remote consoles and restricted environments is a common pain point for sysadmins and developers:

- **IPMI/iLO/iDRAC** web consoles don't support clipboard
- **RDP** without clipboard redirection
- **VMs** without guest additions/tools
- **Web forms** that block the paste event with JavaScript
- **Secure terminals** that disable paste for security

PasteJack solves all of these by simulating keyboard input at the OS level.

## License

Free to use, copy, modify, and distribute. No warranty. Source code not included. See [LICENSE](LICENSE) for details.

Copyright (c) 2026 Wolfgang Vieregg
