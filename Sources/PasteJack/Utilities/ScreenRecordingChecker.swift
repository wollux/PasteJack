import CoreGraphics

/// Check and prompt for macOS Screen Recording permission.
/// Required for ScreenCaptureKit screen capture.
enum ScreenRecordingChecker {

    /// Check if the app has Screen Recording permission.
    static var hasPermission: Bool {
        CGPreflightScreenCaptureAccess()
    }

    /// Prompt the user to grant Screen Recording permission.
    /// Opens System Settings to the Screen Recording pane.
    static func requestPermission() {
        CGRequestScreenCaptureAccess()
    }
}
