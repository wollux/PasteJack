import AppKit

/// Manages a fullscreen transparent overlay for screen region selection.
/// The user drags to select a rectangle, presses Escape to cancel.
@MainActor
final class ScreenSelectionOverlay {

    typealias SelectionHandler = (CGRect?) -> Void

    private var overlayWindow: NSWindow?
    private var handler: SelectionHandler?

    /// Show the selection overlay on the main screen.
    /// Calls handler with the selected CGRect (screen coordinates) or nil if cancelled.
    func show(handler: @escaping SelectionHandler) {
        self.handler = handler

        guard let screen = NSScreen.main else {
            handler(nil)
            return
        }

        // Borderless windows return canBecomeKey = false by default,
        // so we use a subclass that overrides it.
        let window = KeyableWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.level = .screenSaver
        window.isOpaque = false
        window.backgroundColor = .clear
        window.ignoresMouseEvents = false
        window.acceptsMouseMovedEvents = true
        window.hasShadow = false

        let selectionView = SelectionView(frame: screen.frame) { [weak self] rect in
            self?.finish(with: rect)
        }
        window.contentView = selectionView

        // Activate the app first — critical for .accessory policy apps
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(selectionView)

        self.overlayWindow = window

        NSCursor.crosshair.push()
    }

    private func finish(with rect: CGRect?) {
        NSCursor.pop()
        overlayWindow?.orderOut(nil)
        overlayWindow = nil

        // Convert from window coordinates to screen coordinates
        if let rect, let screen = NSScreen.main {
            let screenRect = CGRect(
                x: rect.origin.x,
                y: screen.frame.height - rect.origin.y - rect.height,
                width: rect.width,
                height: rect.height
            )
            handler?(screenRect)
        } else {
            handler?(nil)
        }
        handler = nil
    }
}

// MARK: - Selection NSView

private class SelectionView: NSView {

    typealias CompletionHandler = (CGRect?) -> Void

    private var startPoint: NSPoint?
    private var currentRect: NSRect?
    private let onComplete: CompletionHandler

    // Visual styling
    private let overlayColor = NSColor.black.withAlphaComponent(0.3)
    private let selectionStrokeColor = NSColor.systemBlue
    private let selectionFillColor = NSColor.systemBlue.withAlphaComponent(0.1)
    private let instructionText = "Drag to select a region. Press Esc to cancel."

    init(frame: NSRect, onComplete: @escaping CompletionHandler) {
        self.onComplete = onComplete
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    override var acceptsFirstResponder: Bool { true }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        // Dark overlay
        overlayColor.setFill()
        bounds.fill()

        // Clear the selection area (punch hole in overlay)
        if let rect = currentRect {
            NSColor.clear.setFill()
            rect.fill(using: .copy)

            // Selection rectangle border
            selectionFillColor.setFill()
            rect.fill()

            let borderPath = NSBezierPath(roundedRect: rect, xRadius: 2, yRadius: 2)
            borderPath.lineWidth = 2
            selectionStrokeColor.setStroke()
            borderPath.stroke()

            // Dimension label
            drawDimensionLabel(for: rect)
        }

        // Instruction text at top center
        drawInstructionText()
    }

    private func drawDimensionLabel(for rect: NSRect) {
        let text = "\(Int(rect.width)) × \(Int(rect.height))"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .medium),
            .foregroundColor: NSColor.white,
        ]
        let size = (text as NSString).size(withAttributes: attributes)

        let labelRect = NSRect(
            x: rect.midX - size.width / 2 - 6,
            y: rect.minY - size.height - 10,
            width: size.width + 12,
            height: size.height + 4
        )

        // Background pill
        let pillPath = NSBezierPath(roundedRect: labelRect, xRadius: 4, yRadius: 4)
        NSColor.black.withAlphaComponent(0.7).setFill()
        pillPath.fill()

        // Text
        let textPoint = NSPoint(x: labelRect.origin.x + 6, y: labelRect.origin.y + 2)
        (text as NSString).draw(at: textPoint, withAttributes: attributes)
    }

    private func drawInstructionText() {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 16, weight: .medium),
            .foregroundColor: NSColor.white,
        ]
        let size = (instructionText as NSString).size(withAttributes: attributes)

        let bgRect = NSRect(
            x: bounds.midX - size.width / 2 - 16,
            y: bounds.maxY - 60,
            width: size.width + 32,
            height: size.height + 16
        )

        let pillPath = NSBezierPath(roundedRect: bgRect, xRadius: 8, yRadius: 8)
        NSColor.black.withAlphaComponent(0.6).setFill()
        pillPath.fill()

        let textPoint = NSPoint(x: bgRect.origin.x + 16, y: bgRect.origin.y + 8)
        (instructionText as NSString).draw(at: textPoint, withAttributes: attributes)
    }

    // MARK: - Mouse Events

    override func mouseDown(with event: NSEvent) {
        startPoint = convert(event.locationInWindow, from: nil)
        currentRect = nil
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = startPoint else { return }
        let current = convert(event.locationInWindow, from: nil)

        let x = min(start.x, current.x)
        let y = min(start.y, current.y)
        let w = abs(current.x - start.x)
        let h = abs(current.y - start.y)

        currentRect = NSRect(x: x, y: y, width: w, height: h)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard let rect = currentRect, rect.width > 5, rect.height > 5 else {
            // Too small or no drag — treat as cancel
            onComplete(nil)
            return
        }
        onComplete(rect)
    }

    // MARK: - Keyboard Events

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            onComplete(nil)
        }
    }
}

// MARK: - KeyableWindow

/// Borderless NSWindow subclass that can become key window.
/// Standard borderless windows return false for canBecomeKey,
/// preventing them from receiving keyboard events.
private class KeyableWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
