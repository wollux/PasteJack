import Foundation

enum Constants {
    static let appName = "PasteJack"

    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"
    }
    static let bundleIdentifier = "com.pastejack.app"

    // Default settings
    static let defaultKeystrokeDelayMs: Double = 20
    static let defaultCountdownSeconds: Int = 3
    static let defaultMaxCharacters: Int = 10_000

    // Limits
    static let minDelayMs: Double = 5
    static let maxDelayMs: Double = 200
    static let delayStepMs: Double = 5
    static let minCountdownSeconds: Int = 0
    static let maxCountdownSeconds: Int = 10

    // Hotkey defaults — Paste as Keystrokes
    static let defaultHotkeyKeyCode: UInt32 = 9 // kVK_ANSI_V
    static let defaultHotkeyModifiers: UInt32 = 0x1000 | 0x0200 // controlKey | shiftKey

    // Hotkey defaults — Selected Text Typing
    static let defaultSelectedTextHotkeyKeyCode: UInt32 = 17 // kVK_ANSI_T
    static let defaultSelectedTextHotkeyModifiers: UInt32 = 0x1000 | 0x0200 // controlKey | shiftKey

    // Hotkey defaults — OCR Copy from Screen
    static let defaultOCRHotkeyKeyCode: UInt32 = 8 // kVK_ANSI_C
    static let defaultOCRHotkeyModifiers: UInt32 = 0x1000 | 0x0200 // controlKey | shiftKey

    // OCR defaults
    static let defaultOCRAutoCloseSeconds: Int = 8
    static let minOCRAutoCloseSeconds: Int = 3
    static let maxOCRAutoCloseSeconds: Int = 15

    // Adaptive speed
    static let adaptiveSpeedMultiplier: Double = 1.5
    static let adaptiveSpeedWindow: Int = 50

    // Line delay
    static let defaultLineDelayMs: Double = 0
    static let maxLineDelayMs: Double = 2000
    static let lineDelayStepMs: Double = 50
}
