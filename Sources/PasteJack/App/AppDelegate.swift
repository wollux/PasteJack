import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private let hotkeyManager = HotkeyManager(id: 1)
    private let ocrHotkeyManager = HotkeyManager(id: 2)
    private let session = TypingSession()
    private var cancellable: Any?
    private var settingsWindow: NSWindow?
    private var onboardingWindow: NSWindow?
    private var ocrResultWindow: NSWindow?
    private let screenSelection = ScreenSelectionOverlay()
    private var popover: NSPopover?
    private var eventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Wrap bare executable in .app bundle for stable TCC permissions.
        // If not already in a bundle, this creates one, re-launches, and exits.
        DevBundleHelper.ensureRunningFromBundle()

        // Hide Dock icon — menu bar only
        NSApp.setActivationPolicy(.accessory)

        // Close the empty SwiftUI Settings window after it's created
        DispatchQueue.main.async {
            for window in NSApp.windows {
                if window.title.contains("Settings") || window.contentView?.subviews.isEmpty == true {
                    window.orderOut(nil)
                }
            }
        }

        setupStatusItem()

        // Show onboarding only on first launch — not on every restart
        if !UserSettings.shared.hasSeenOnboarding {
            showOnboarding()
        }

        // Listen for manual "show onboarding" requests from Settings
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showOnboardingFromNotification),
            name: .showOnboarding,
            object: nil
        )

        // Register global hotkey: Ctrl+Shift+V → Paste as Keystrokes
        hotkeyManager.register { [weak self] in
            Task { @MainActor in
                self?.handleHotkey()
            }
        }

        // Register global hotkey: Ctrl+Shift+C → Copy from Screen (OCR)
        ocrHotkeyManager.register(
            keyCode: Constants.defaultOCRHotkeyKeyCode,
            modifiers: Constants.defaultOCRHotkeyModifiers
        ) { [weak self] in
            Task { @MainActor in
                self?.handleOCRHotkey()
            }
        }

        // Observe session state changes to update menu bar icon
        cancellable = session.$state.sink { [weak self] state in
            Task { @MainActor in
                self?.updateStatusIcon(for: state)
            }
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: StatusIndicator.symbolName(for: .idle),
                accessibilityDescription: Constants.appName
            )
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    // MARK: - Popover Menu

    @objc private func togglePopover() {
        if let popover, popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        let menuView = MenuBarView(
            session: session,
            onPaste: { [weak self] in self?.handleHotkey() },
            onOCR: { [weak self] in self?.handleOCRHotkey() },
            onCancel: { [weak self] in self?.cancelTyping() },
            onSettings: { [weak self] in self?.openSettings() },
            onQuit: { NSApp.terminate(nil) },
            dismissPopover: { [weak self] in self?.closePopover() }
        )

        let pop = NSPopover()
        pop.contentSize = NSSize(width: 260, height: 1) // height auto-sizes
        pop.behavior = .transient
        pop.contentViewController = NSHostingController(rootView: menuView)

        if let button = statusItem.button {
            pop.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
        self.popover = pop

        // Close popover when clicking outside
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }
    }

    private func closePopover() {
        popover?.performClose(nil)
        popover = nil

        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
        eventMonitor = nil
    }

    // MARK: - Paste as Keystrokes

    @objc private func handleHotkey() {
        guard AccessibilityChecker.hasPermission else {
            showOnboarding()
            return
        }

        guard !session.isActive else { return }

        guard let text = ClipboardReader.readString(), !text.isEmpty else {
            return
        }

        let settings = UserSettings.shared

        guard text.count <= settings.maxCharacters else {
            session.state = .error("Text too long (\(text.count) chars, max \(settings.maxCharacters))")
            return
        }

        session.start(
            text: text,
            delayMicroseconds: settings.delayMicroseconds,
            countdownSeconds: settings.countdownSeconds
        )
    }

    @objc private func cancelTyping() {
        session.cancel()
    }

    // MARK: - OCR Copy from Screen

    @objc private func handleOCRHotkey() {
        guard ScreenRecordingChecker.hasPermission else {
            ScreenRecordingChecker.requestPermission()
            return
        }

        startOCRSelection()
    }

    private func startOCRSelection() {
        screenSelection.show { [weak self] rect in
            guard let self, let rect else { return }

            Task { @MainActor in
                await self.performOCR(on: rect)
            }
        }
    }

    private func performOCR(on rect: CGRect) async {
        guard let image = await ScreenCapture.captureRect(rect) else { return }

        do {
            let text = try await OCREngine.recognizeText(from: image)
            showOCRResult(text: text)
        } catch {
            showOCRResult(text: "")
        }
    }

    private func showOCRResult(text: String) {
        ocrResultWindow?.close()

        guard !text.isEmpty else { return }

        let window = NSWindow(
            contentRect: .zero,
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.title = "PasteJack — OCR Result"
        window.contentView = NSHostingView(
            rootView: OCRResultView(
                text: text,
                onTypeIt: { [weak self] editedText in
                    self?.ocrResultWindow?.close()
                    guard AccessibilityChecker.hasPermission else {
                        self?.showOnboarding()
                        return
                    }
                    let settings = UserSettings.shared
                    self?.session.start(
                        text: editedText,
                        delayMicroseconds: settings.delayMicroseconds,
                        countdownSeconds: 0
                    )
                },
                onTryAgain: { [weak self] in
                    self?.ocrResultWindow?.close()
                    self?.startOCRSelection()
                },
                onDismiss: { [weak self] in
                    self?.ocrResultWindow?.close()
                }
            )
        )
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.ocrResultWindow = window
    }

    // MARK: - Settings & Onboarding Windows

    @objc private func openSettings() {
        if let settingsWindow, settingsWindow.isVisible {
            settingsWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: .zero,
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.title = "PasteJack Settings"
        window.contentView = NSHostingView(rootView: SettingsView())
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.settingsWindow = window
    }

    @objc private func showOnboardingFromNotification() {
        showOnboarding()
    }

    private func showOnboarding() {
        if let onboardingWindow, onboardingWindow.isVisible {
            onboardingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: .zero,
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.title = "PasteJack"
        window.contentView = NSHostingView(
            rootView: AccessibilityOnboardingView(onDismiss: { [weak self] in
                self?.onboardingWindow?.close()
            })
        )
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.onboardingWindow = window
    }

    // MARK: - Status Icon

    private func updateStatusIcon(for state: TypingSession.State) {
        let settings = UserSettings.shared

        guard settings.showProgress else {
            if case .error = state {
                StatusIndicator.update(statusItem.button, state: .error)
            }
            return
        }

        let iconState: StatusIndicator.IconState
        switch state {
        case .idle:
            iconState = .idle
        case .countdown:
            iconState = .countdown
        case .typing:
            iconState = .typing
        case .completed:
            iconState = .completed
            if settings.playSoundOnComplete {
                NSSound(named: "Glass")?.play()
            }
            Task {
                try? await Task.sleep(for: .seconds(2))
                StatusIndicator.update(statusItem.button, state: .idle)
            }
        case .cancelled:
            iconState = .idle
        case .error:
            iconState = .error
        }
        StatusIndicator.update(statusItem.button, state: iconState)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let showOnboarding = Notification.Name("PasteJack.showOnboarding")
}
