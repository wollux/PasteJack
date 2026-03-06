import ServiceManagement
import SwiftUI

/// Centralized user preferences using @AppStorage.
final class UserSettings: ObservableObject {

    static let shared = UserSettings()

    /// Delay between keystrokes in milliseconds
    @AppStorage("keystrokeDelayMs") var keystrokeDelayMs: Double = Constants.defaultKeystrokeDelayMs

    /// Countdown seconds before typing starts
    @AppStorage("countdownSeconds") var countdownSeconds: Int = Constants.defaultCountdownSeconds

    /// Whether to launch at login — wired to SMAppService
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false {
        didSet { updateLaunchAtLogin() }
    }

    /// Play sound on completion
    @AppStorage("playSoundOnComplete") var playSoundOnComplete: Bool = true

    /// Show typing progress in menu bar
    @AppStorage("showProgress") var showProgress: Bool = true

    /// Maximum characters to type (safety limit)
    @AppStorage("maxCharacters") var maxCharacters: Int = Constants.defaultMaxCharacters

    // MARK: - Onboarding

    /// Whether the user has completed the initial onboarding
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false

    // MARK: - Adaptive Speed

    /// Enable adaptive speed that slows down when target app can't keep up
    @AppStorage("adaptiveSpeed") var adaptiveSpeed: Bool = false

    // MARK: - Line Delay

    /// Extra delay after newlines in milliseconds (0 = disabled)
    @AppStorage("lineDelayMs") var lineDelayMs: Double = Constants.defaultLineDelayMs

    /// Computed: line delay in microseconds for usleep()
    var lineDelayMicroseconds: UInt32 {
        UInt32(lineDelayMs * 1000)
    }

    // MARK: - Notifications

    /// Show macOS notification when typing completes
    @AppStorage("showNotification") var showNotification: Bool = true

    // MARK: - Sensitive Detection

    /// Warn when clipboard contains potential secrets
    @AppStorage("sensitiveDetection") var sensitiveDetection: Bool = true

    // MARK: - Appearance

    /// Appearance mode: "system", "dark", "light"
    @AppStorage("appearanceMode") var appearanceMode: String = "system"

    // MARK: - Preview

    /// Show preview window before typing
    @AppStorage("showPreview") var showPreview: Bool = false

    // MARK: - Custom Hotkeys

    /// Paste hotkey key code (default: kVK_ANSI_V = 9)
    @AppStorage("pasteHotkeyKeyCode") var pasteHotkeyKeyCode: Int = Int(Constants.defaultHotkeyKeyCode)
    /// Paste hotkey modifiers
    @AppStorage("pasteHotkeyModifiers") var pasteHotkeyModifiers: Int = Int(Constants.defaultHotkeyModifiers)

    /// OCR hotkey key code (default: kVK_ANSI_C = 8)
    @AppStorage("ocrHotkeyKeyCode") var ocrHotkeyKeyCode: Int = Int(Constants.defaultOCRHotkeyKeyCode)
    /// OCR hotkey modifiers
    @AppStorage("ocrHotkeyModifiers") var ocrHotkeyModifiers: Int = Int(Constants.defaultOCRHotkeyModifiers)

    /// Selected text hotkey key code (default: kVK_ANSI_T = 17)
    @AppStorage("selectedTextHotkeyKeyCode") var selectedTextHotkeyKeyCode: Int = Int(Constants.defaultSelectedTextHotkeyKeyCode)
    /// Selected text hotkey modifiers
    @AppStorage("selectedTextHotkeyModifiers") var selectedTextHotkeyModifiers: Int = Int(Constants.defaultSelectedTextHotkeyModifiers)

    // MARK: - OCR Language

    /// Preferred OCR language (empty = auto-detect)
    @AppStorage("ocrPreferredLanguage") var ocrPreferredLanguage: String = ""

    // MARK: - OCR Settings

    /// Auto-close OCR result window
    @AppStorage("ocrAutoClose") var ocrAutoClose: Bool = false

    /// Seconds before OCR result window auto-closes
    @AppStorage("ocrAutoCloseSeconds") var ocrAutoCloseSeconds: Int = Constants.defaultOCRAutoCloseSeconds

    // MARK: - License

    /// License key entered by the user
    @AppStorage("licenseKey") var licenseKey: String = ""

    /// Whether the license has been validated successfully
    @AppStorage("licenseValid") var licenseValid: Bool = false

    /// Number of uses today
    @AppStorage("dailyUseCount") var dailyUseCount: Int = 0

    /// Date string for the current day's usage counter (yyyy-MM-dd)
    @AppStorage("dailyUseDate") var dailyUseDate: String = ""

    /// Total lifetime paste-as-keystrokes uses
    @AppStorage("totalPasteCount") var totalPasteCount: Int = 0

    /// Total lifetime OCR uses
    @AppStorage("totalOCRCount") var totalOCRCount: Int = 0

    /// Total lifetime characters typed
    @AppStorage("totalCharsTyped") var totalCharsTyped: Int = 0

    /// Computed: delay in microseconds for usleep()
    var delayMicroseconds: UInt32 {
        UInt32(keystrokeDelayMs * 1000)
    }

    private func updateLaunchAtLogin() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Silently fail — SMAppService requires a proper app bundle
            // which only exists in release builds, not during swift run
        }
    }
}
