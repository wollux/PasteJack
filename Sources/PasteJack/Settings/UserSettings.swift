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
