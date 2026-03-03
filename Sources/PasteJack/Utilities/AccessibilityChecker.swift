import ApplicationServices

/// Check and prompt for macOS Accessibility permission.
/// Required for CGEvent keystroke simulation.
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
