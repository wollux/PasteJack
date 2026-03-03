import CoreGraphics
import ScreenCaptureKit
import AppKit

/// Captures a region of the screen as a CGImage.
enum ScreenCapture {

    /// Capture a rectangular region of the screen using ScreenCaptureKit.
    /// The rect uses screen coordinates (origin = top-left of main display).
    static func captureRect(_ rect: CGRect) async -> CGImage? {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            guard let display = content.displays.first else { return nil }

            let filter = SCContentFilter(display: display, excludingWindows: [])
            let config = SCStreamConfiguration()

            // Convert rect from screen coordinates to display pixel coordinates
            let scale = CGFloat(display.width) / NSScreen.main!.frame.width

            config.sourceRect = CGRect(
                x: rect.origin.x * scale,
                y: rect.origin.y * scale,
                width: rect.width * scale,
                height: rect.height * scale
            )
            config.width = Int(rect.width * scale)
            config.height = Int(rect.height * scale)
            config.showsCursor = false

            let image = try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: config
            )
            return image
        } catch {
            return nil
        }
    }
}
