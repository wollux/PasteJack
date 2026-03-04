import AppKit

/// Manages a fullscreen transparent overlay for screen region selection.
/// The user drags to select a rectangle, presses Escape to cancel.
@MainActor
final class ScreenSelectionOverlay {

    typealias SelectionHandler = (CGRect?) -> Void
    typealias MultiSelectionHandler = ([CGRect]) -> Void

    private var overlayWindow: NSWindow?
    private var handler: SelectionHandler?
    private var multiHandler: MultiSelectionHandler?

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

    /// Show multi-region selection overlay. User can select multiple regions.
    /// Press Enter to finish, Escape to cancel.
    func showMultiRegion(handler: @escaping MultiSelectionHandler) {
        self.multiHandler = handler

        guard let screen = NSScreen.main else {
            handler([])
            return
        }

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

        let selectionView = MultiSelectionView(frame: screen.frame) { [weak self] rects in
            self?.finishMulti(with: rects)
        }
        window.contentView = selectionView

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

    private func finishMulti(with rects: [CGRect]) {
        NSCursor.pop()
        overlayWindow?.orderOut(nil)
        overlayWindow = nil

        guard let screen = NSScreen.main else {
            multiHandler?([])
            multiHandler = nil
            return
        }

        let screenRects = rects.map { rect in
            CGRect(
                x: rect.origin.x,
                y: screen.frame.height - rect.origin.y - rect.height,
                width: rect.width,
                height: rect.height
            )
        }
        multiHandler?(screenRects)
        multiHandler = nil
    }
}

// MARK: - Selection NSView

private class SelectionView: NSView {

    typealias CompletionHandler = (CGRect?) -> Void

    private var startPoint: NSPoint?
    private var currentRect: NSRect?
    private let onComplete: CompletionHandler

    // Visual styling — sky-blue (#38BDF8)
    private let overlayColor = NSColor.black.withAlphaComponent(0.3)
    private let selectionStrokeColor = NSColor(red: 0.22, green: 0.74, blue: 0.97, alpha: 1.0)
    private let selectionFillColor = NSColor(red: 0.22, green: 0.74, blue: 0.97, alpha: 0.08)
    private let handleColor = NSColor(red: 0.22, green: 0.74, blue: 0.97, alpha: 1.0)
    private let handleBorderColor = NSColor(red: 0.05, green: 0.65, blue: 0.89, alpha: 1.0)
    private let handleSize: CGFloat = 9
    private let instructionText = "Drag to select a region \u{00B7} Press Esc to cancel"

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

            // Selection rectangle fill
            selectionFillColor.setFill()
            rect.fill()

            // Selection rectangle border
            let borderPath = NSBezierPath(roundedRect: rect, xRadius: 3, yRadius: 3)
            borderPath.lineWidth = 2
            selectionStrokeColor.setStroke()
            borderPath.stroke()

            // Corner handles
            drawCornerHandles(for: rect)

            // Dimension label above the selection
            drawDimensionLabel(for: rect)
        }

        // Instruction pill at bottom center
        drawInstructionPill()
    }

    private func drawCornerHandles(for rect: NSRect) {
        let half = handleSize / 2
        let corners: [NSPoint] = [
            NSPoint(x: rect.minX - half, y: rect.minY - half),     // bottom-left
            NSPoint(x: rect.maxX - half, y: rect.minY - half),     // bottom-right
            NSPoint(x: rect.minX - half, y: rect.maxY - half),     // top-left
            NSPoint(x: rect.maxX - half, y: rect.maxY - half),     // top-right
        ]

        for corner in corners {
            let handleRect = NSRect(x: corner.x, y: corner.y, width: handleSize, height: handleSize)
            let handlePath = NSBezierPath(roundedRect: handleRect, xRadius: 2, yRadius: 2)

            handleColor.setFill()
            handlePath.fill()

            handleBorderColor.setStroke()
            handlePath.lineWidth = 1.5
            handlePath.stroke()
        }
    }

    private func drawDimensionLabel(for rect: NSRect) {
        let text = "\(Int(rect.width)) \u{00D7} \(Int(rect.height))"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .medium),
            .foregroundColor: NSColor.white.withAlphaComponent(0.8),
        ]
        let size = (text as NSString).size(withAttributes: attributes)

        // Position above the selection rectangle
        let labelRect = NSRect(
            x: rect.midX - size.width / 2 - 8,
            y: rect.maxY + 8,
            width: size.width + 16,
            height: size.height + 6
        )

        // Background pill
        let pillPath = NSBezierPath(roundedRect: labelRect, xRadius: 4, yRadius: 4)
        NSColor.black.withAlphaComponent(0.75).setFill()
        pillPath.fill()

        // Border
        NSColor.white.withAlphaComponent(0.1).setStroke()
        pillPath.lineWidth = 1
        pillPath.stroke()

        // Text
        let textPoint = NSPoint(x: labelRect.origin.x + 8, y: labelRect.origin.y + 3)
        (text as NSString).draw(at: textPoint, withAttributes: attributes)
    }

    private func drawInstructionPill() {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .medium),
            .foregroundColor: NSColor.white.withAlphaComponent(0.65),
        ]
        let size = (instructionText as NSString).size(withAttributes: attributes)

        // Position at bottom center
        let bgRect = NSRect(
            x: bounds.midX - size.width / 2 - 18,
            y: 18,
            width: size.width + 36,
            height: size.height + 12
        )

        // Capsule background
        let pillPath = NSBezierPath(roundedRect: bgRect, xRadius: bgRect.height / 2, yRadius: bgRect.height / 2)
        NSColor.black.withAlphaComponent(0.7).setFill()
        pillPath.fill()

        // Border
        NSColor.white.withAlphaComponent(0.1).setStroke()
        pillPath.lineWidth = 1
        pillPath.stroke()

        // Text
        let textPoint = NSPoint(x: bgRect.origin.x + 18, y: bgRect.origin.y + 6)
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

// MARK: - Multi-Region Selection View

private class MultiSelectionView: NSView {

    typealias CompletionHandler = ([CGRect]) -> Void

    private var startPoint: NSPoint?
    private var currentRect: NSRect?
    private var completedRegions: [NSRect] = []
    private let onComplete: CompletionHandler

    private let overlayColor = NSColor.black.withAlphaComponent(0.3)
    private let selectionStrokeColor = NSColor(red: 0.22, green: 0.74, blue: 0.97, alpha: 1.0)
    private let selectionFillColor = NSColor(red: 0.22, green: 0.74, blue: 0.97, alpha: 0.08)
    private let completedStrokeColor = NSColor(red: 0.22, green: 0.74, blue: 0.97, alpha: 0.6)
    private let handleColor = NSColor(red: 0.22, green: 0.74, blue: 0.97, alpha: 1.0)
    private let handleSize: CGFloat = 9

    init(frame: NSRect, onComplete: @escaping CompletionHandler) {
        self.onComplete = onComplete
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    override var acceptsFirstResponder: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        overlayColor.setFill()
        bounds.fill()

        // Draw completed regions
        for (index, rect) in completedRegions.enumerated() {
            NSColor.clear.setFill()
            rect.fill(using: .copy)
            selectionFillColor.setFill()
            rect.fill()

            let borderPath = NSBezierPath(roundedRect: rect, xRadius: 3, yRadius: 3)
            borderPath.lineWidth = 2
            completedStrokeColor.setStroke()
            borderPath.stroke()

            // Region number
            let numText = "\(index + 1)"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedSystemFont(ofSize: 14, weight: .bold),
                .foregroundColor: NSColor.white.withAlphaComponent(0.7),
            ]
            let numSize = (numText as NSString).size(withAttributes: attrs)
            let numPoint = NSPoint(x: rect.midX - numSize.width / 2, y: rect.midY - numSize.height / 2)
            (numText as NSString).draw(at: numPoint, withAttributes: attrs)
        }

        // Draw current selection
        if let rect = currentRect {
            NSColor.clear.setFill()
            rect.fill(using: .copy)
            selectionFillColor.setFill()
            rect.fill()

            let borderPath = NSBezierPath(roundedRect: rect, xRadius: 3, yRadius: 3)
            borderPath.lineWidth = 2
            selectionStrokeColor.setStroke()
            borderPath.stroke()
        }

        // Instruction
        let text = completedRegions.isEmpty
            ? "Drag to select a region \u{00B7} Press Esc to cancel"
            : "\(completedRegions.count) region\(completedRegions.count == 1 ? "" : "s") \u{00B7} Drag for more \u{00B7} Enter to finish \u{00B7} Esc to cancel"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .medium),
            .foregroundColor: NSColor.white.withAlphaComponent(0.65),
        ]
        let size = (text as NSString).size(withAttributes: attributes)
        let bgRect = NSRect(
            x: bounds.midX - size.width / 2 - 18,
            y: 18,
            width: size.width + 36,
            height: size.height + 12
        )
        let pillPath = NSBezierPath(roundedRect: bgRect, xRadius: bgRect.height / 2, yRadius: bgRect.height / 2)
        NSColor.black.withAlphaComponent(0.7).setFill()
        pillPath.fill()
        let textPoint = NSPoint(x: bgRect.origin.x + 18, y: bgRect.origin.y + 6)
        (text as NSString).draw(at: textPoint, withAttributes: attributes)
    }

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
        guard let rect = currentRect, rect.width > 5, rect.height > 5 else { return }
        completedRegions.append(rect)
        currentRect = nil
        needsDisplay = true
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            onComplete([])
        } else if event.keyCode == 36 { // Enter
            onComplete(completedRegions)
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
