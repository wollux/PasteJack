import AppKit
import SwiftUI
import UserNotifications

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private let hotkeyManager = HotkeyManager(id: 1)
    private let ocrHotkeyManager = HotkeyManager(id: 2)
    private let selectedTextHotkeyManager = HotkeyManager(id: 3)
    private let session = TypingSession()
    private var cancellable: Any?
    private var settingsWindow: NSWindow?
    private var onboardingWindow: NSWindow?
    private var ocrResultWindow: NSWindow?
    private var typingOverlayWindow: NSWindow?
    private var previewWindow: NSWindow?
    private let screenSelection = ScreenSelectionOverlay()
    private var nagWindow: NSWindow?
    private var popover: NSPopover?
    private var eventMonitor: Any?
    private var escapeMonitor: Any?
    private var queueWindow: NSWindow?
    private let typingQueue = TypingQueue()
    private let clipboardHistory = ClipboardHistory.shared
    private var whatsNewWindow: NSWindow?
    private let updateManager = UpdateManager()

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

        // Apply appearance preference
        applyAppearance()

        // Request notification permission
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }

        // Register global hotkey: Ctrl+Shift+V → Paste as Keystrokes
        hotkeyManager.register(
            keyCode: UInt32(UserSettings.shared.pasteHotkeyKeyCode),
            modifiers: UInt32(UserSettings.shared.pasteHotkeyModifiers)
        ) { [weak self] in
            Task { @MainActor in
                self?.handleHotkey()
            }
        }

        // Register global hotkey: Ctrl+Shift+C → Copy from Screen (OCR)
        ocrHotkeyManager.register(
            keyCode: UInt32(UserSettings.shared.ocrHotkeyKeyCode),
            modifiers: UInt32(UserSettings.shared.ocrHotkeyModifiers)
        ) { [weak self] in
            Task { @MainActor in
                self?.handleOCRHotkey()
            }
        }

        // Register global hotkey: Ctrl+Shift+T → Type Selected Text
        selectedTextHotkeyManager.register(
            keyCode: UInt32(UserSettings.shared.selectedTextHotkeyKeyCode),
            modifiers: UInt32(UserSettings.shared.selectedTextHotkeyModifiers)
        ) { [weak self] in
            Task { @MainActor in
                self?.handleSelectedTextHotkey()
            }
        }

        // Observe hotkey setting changes to re-register
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(hotkeySettingsChanged),
            name: UserDefaults.didChangeNotification,
            object: nil
        )

        // Observe session state changes to update menu bar icon
        cancellable = session.$state.sink { [weak self] state in
            Task { @MainActor in
                self?.updateStatusIcon(for: state)
            }
        }

        // Start clipboard history monitoring
        clipboardHistory.startMonitoring()

        // Show What's New after update (but not on first launch)
        let settings = UserSettings.shared
        if settings.hasSeenOnboarding && settings.lastSeenVersion != Constants.appVersion {
            showWhatsNew()
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

    // MARK: - Window Helper

    /// Creates a standard PasteJack window with transparent titlebar.
    private func makeWindow<Content: SwiftUI.View>(
        title: String,
        resizable: Bool = false,
        content: Content
    ) -> NSWindow {
        var styleMask: NSWindow.StyleMask = [.titled, .closable, .fullSizeContentView]
        if resizable { styleMask.insert(.resizable) }

        let window = NSWindow(
            contentRect: .zero,
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.title = title
        window.contentView = NSHostingView(rootView: content)
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        return window
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
            onSelectedText: { [weak self] in self?.handleSelectedTextHotkey() },
            onMultiOCR: { [weak self] in self?.startMultiRegionOCR() },
            onCancel: { [weak self] in self?.cancelTyping() },
            onSettings: { [weak self] in self?.openSettings() },
            onSnippets: { [weak self] in self?.openSnippetLibrary() },
            onQuit: { NSApp.terminate(nil) },
            dismissPopover: { [weak self] in self?.closePopover() },
            onTypingHistory: { [weak self] in self?.openTypingHistory() },
            onOCRHistory: { [weak self] in self?.openOCRHistory() },
            onQueue: { [weak self] in self?.openQueue() },
            onTypeText: { [weak self] text in self?.startTypingSession(text: text) },
            onCheckForUpdates: { [weak self] in self?.updateManager.checkForUpdates() }
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

        // Sensitive content detection
        if settings.sensitiveDetection {
            let matches = SensitiveDetector.detect(in: text)
            if !matches.isEmpty {
                let types = matches.map(\.type.rawValue).joined(separator: ", ")
                let alert = NSAlert()
                alert.messageText = "Sensitive Content Detected"
                alert.informativeText = "Clipboard may contain: \(types).\nType anyway?"
                alert.alertStyle = .warning
                alert.addButton(withTitle: "Type Anyway")
                alert.addButton(withTitle: "Cancel")
                NSApp.activate(ignoringOtherApps: true)
                let response = alert.runModal()
                if response != .alertFirstButtonReturn { return }
            }
        }

        // Preview mode
        if settings.showPreview {
            showTypingPreview(text: text)
            return
        }

        startTypingSession(text: text)
    }

    private func startTypingSession(text: String, postTypingAction: String? = nil) {
        let settings = UserSettings.shared
        session.start(
            text: text,
            delayMicroseconds: settings.delayMicroseconds,
            countdownSeconds: settings.countdownSeconds,
            adaptiveSpeed: settings.adaptiveSpeed,
            lineDelayMicroseconds: settings.lineDelayMicroseconds,
            postTypingAction: postTypingAction ?? settings.postTypingAction,
            targetLayout: TargetLayout(rawValue: settings.targetLayout) ?? .auto
        )
    }

    private func showTypingPreview(text: String) {
        previewWindow?.close()
        previewWindow = makeWindow(
            title: "PasteJack \u{2014} Preview",
            content: TypingPreviewView(
                text: text,
                delayMs: UserSettings.shared.keystrokeDelayMs,
                onStart: { [weak self] in
                    self?.previewWindow?.close()
                    self?.startTypingSession(text: text)
                },
                onCancel: { [weak self] in
                    self?.previewWindow?.close()
                }
            )
        )
    }

    @objc private func cancelTyping() {
        session.cancel()
    }

    // MARK: - Hotkey Re-registration

    // MARK: - Appearance

    private func applyAppearance() {
        switch UserSettings.shared.appearanceMode {
        case "dark":
            NSApp.appearance = NSAppearance(named: .darkAqua)
        case "light":
            NSApp.appearance = NSAppearance(named: .aqua)
        default:
            NSApp.appearance = nil // system default
        }
    }

    @objc private func hotkeySettingsChanged() {
        let s = UserSettings.shared
        hotkeyManager.reregister(keyCode: UInt32(s.pasteHotkeyKeyCode), modifiers: UInt32(s.pasteHotkeyModifiers))
        ocrHotkeyManager.reregister(keyCode: UInt32(s.ocrHotkeyKeyCode), modifiers: UInt32(s.ocrHotkeyModifiers))
        selectedTextHotkeyManager.reregister(keyCode: UInt32(s.selectedTextHotkeyKeyCode), modifiers: UInt32(s.selectedTextHotkeyModifiers))
        applyAppearance()
    }

    // MARK: - Type Selected Text

    @objc private func handleSelectedTextHotkey() {
        guard AccessibilityChecker.hasPermission else {
            showOnboarding()
            return
        }

        guard !session.isActive else { return }

        // Simulate Cmd+C to copy selection
        let engine = KeystrokeEngine()
        engine.simulateCopy()

        // Wait for clipboard to update then type it
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))

            guard let text = ClipboardReader.readString(), !text.isEmpty else { return }

            let settings = UserSettings.shared
            guard text.count <= settings.maxCharacters else {
                session.state = .error("Text too long (\(text.count) chars, max \(settings.maxCharacters))")
                return
            }

            session.start(
                text: text,
                delayMicroseconds: settings.delayMicroseconds,
                countdownSeconds: 0, // No countdown for selected text
                adaptiveSpeed: settings.adaptiveSpeed,
                lineDelayMicroseconds: settings.lineDelayMicroseconds,
                postTypingAction: settings.postTypingAction,
                targetLayout: TargetLayout(rawValue: settings.targetLayout) ?? .auto
            )
        }
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
        startMultiRegionOCR()
    }

    private func startMultiRegionOCR() {
        screenSelection.showMultiRegion { [weak self] rects in
            guard let self, !rects.isEmpty else { return }
            Task { @MainActor in
                await self.performMultiRegionOCR(on: rects)
            }
        }
    }

    private func performMultiRegionOCR(on rects: [CGRect]) async {
        let preferredLang = UserSettings.shared.ocrPreferredLanguage
        let languages: [String]? = preferredLang.isEmpty ? nil : [preferredLang]

        var allTexts: [String] = []
        var allLanguages: [String] = []

        for rect in rects {
            guard let image = await ScreenCapture.captureRect(rect) else { continue }
            do {
                let result = try await OCREngine.recognizeText(from: image, preferredLanguages: languages)
                allTexts.append(result.text)
                for lang in result.detectedLanguages where !allLanguages.contains(lang) {
                    allLanguages.append(lang)
                }
            } catch {
                // Skip failed regions
            }
        }

        let combinedText = allTexts.joined(separator: "\n---\n")
        guard !combinedText.isEmpty else { return }

        OCRHistory.shared.add(text: combinedText, detectedLanguages: allLanguages)
        showOCRResult(text: combinedText, detectedLanguages: allLanguages)
    }

    private func performOCR(on rect: CGRect) async {
        guard let image = await ScreenCapture.captureRect(rect) else { return }

        let preferredLang = UserSettings.shared.ocrPreferredLanguage
        let languages: [String]? = preferredLang.isEmpty ? nil : [preferredLang]

        do {
            let result = try await OCREngine.recognizeText(from: image, preferredLanguages: languages)
            OCRHistory.shared.add(text: result.text, detectedLanguages: result.detectedLanguages)
            showOCRResult(text: result.text, detectedLanguages: result.detectedLanguages)
        } catch {
            showOCRResult(text: "", detectedLanguages: [])
        }
    }

    private func showOCRResult(text: String, detectedLanguages: [String] = []) {
        ocrResultWindow?.close()

        guard !text.isEmpty else { return }

        UserSettings.shared.totalOCRCount += 1
        UserSettings.shared.totalCharsTyped += text.count
        LicenseManager.shared.recordUsage()
        Task {
            try? await Task.sleep(for: .seconds(1))
            if LicenseManager.shared.shouldShowNag() {
                showSupportNag()
            }
        }

        self.ocrResultWindow = makeWindow(
            title: "PasteJack \u{2014} OCR Result",
            content: OCRResultView(
                text: text,
                detectedLanguages: detectedLanguages,
                onTypeIt: { [weak self] editedText in
                    self?.ocrResultWindow?.close()
                    guard AccessibilityChecker.hasPermission else {
                        self?.showOnboarding()
                        return
                    }
                    self?.startTypingSession(text: editedText)
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
    }

    // MARK: - Snippet Library

    private var snippetWindow: NSWindow?

    @objc private func openSnippetLibrary() {
        if let snippetWindow, snippetWindow.isVisible {
            snippetWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        self.snippetWindow = makeWindow(
            title: "PasteJack \u{2014} Snippets",
            resizable: true,
            content: SnippetLibraryView(
                onTypeSnippet: { [weak self] text in
                    self?.snippetWindow?.close()
                    guard AccessibilityChecker.hasPermission else {
                        self?.showOnboarding()
                        return
                    }
                    let resolved = SnippetVariableResolver.resolve(text)
                    self?.startTypingSession(text: resolved)
                }
            )
        )
    }

    // MARK: - History Windows

    private var typingHistoryWindow: NSWindow?
    private var ocrHistoryWindow: NSWindow?

    @objc private func openTypingHistory() {
        if let typingHistoryWindow, typingHistoryWindow.isVisible {
            typingHistoryWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        self.typingHistoryWindow = makeWindow(
            title: "PasteJack \u{2014} Typing History",
            resizable: true,
            content: TypingHistoryView(
                onTypeEntry: { [weak self] text in
                    self?.typingHistoryWindow?.close()
                    self?.startTypingSession(text: text)
                }
            )
        )
    }

    @objc private func openOCRHistory() {
        if let ocrHistoryWindow, ocrHistoryWindow.isVisible {
            ocrHistoryWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        self.ocrHistoryWindow = makeWindow(
            title: "PasteJack \u{2014} OCR History",
            resizable: true,
            content: OCRHistoryView(
                onTypeEntry: { [weak self] text in
                    self?.ocrHistoryWindow?.close()
                    self?.startTypingSession(text: text)
                }
            )
        )
    }

    // MARK: - Support Nag

    private func showSupportNag() {
        guard nagWindow?.isVisible != true else { return }

        self.nagWindow = makeWindow(
            title: "PasteJack",
            content: SupportNagView(onDismiss: { [weak self] in
                self?.nagWindow?.close()
            })
        )
    }

    // MARK: - URL Scheme Handler

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls { handleURL(url) }
    }

    private func handleURL(_ url: URL) {
        guard url.scheme == "pastejack",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }

        switch url.host {
        case "type":
            if let text = components.queryItems?.first(where: { $0.name == "text" })?.value {
                startTypingSession(text: text)
            } else if let name = components.queryItems?.first(where: { $0.name == "snippet" })?.value,
                      let snippet = SnippetStore.shared.snippets.first(where: { $0.name == name }) {
                let resolved = SnippetVariableResolver.resolve(snippet.text)
                startTypingSession(text: resolved)
            }
        case "ocr":
            handleOCRHotkey()
        default:
            break
        }
    }

    // MARK: - Typing Queue

    @objc private func openQueue() {
        if let queueWindow, queueWindow.isVisible {
            queueWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        self.queueWindow = makeWindow(
            title: "PasteJack \u{2014} Typing Queue",
            resizable: true,
            content: TypingQueueView(
                queue: typingQueue,
                session: session,
                onExecute: { [weak self] in
                    guard let self else { return }
                    Task { @MainActor in
                        await self.typingQueue.execute(
                            session: self.session,
                            settings: UserSettings.shared
                        )
                    }
                },
                onCancel: { [weak self] in
                    self?.session.cancel()
                    self?.typingQueue.stop()
                }
            )
        )
    }

    // MARK: - What's New

    private func showWhatsNew() {
        guard whatsNewWindow?.isVisible != true else { return }

        self.whatsNewWindow = makeWindow(
            title: "PasteJack \u{2014} What's New",
            content: WhatsNewView(onDismiss: { [weak self] in
                self?.whatsNewWindow?.close()
            })
        )
    }

    // MARK: - Settings & Onboarding Windows

    @objc private func openSettings() {
        if let settingsWindow, settingsWindow.isVisible {
            settingsWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        self.settingsWindow = makeWindow(
            title: "PasteJack Settings",
            content: SettingsView()
        )
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

        self.onboardingWindow = makeWindow(
            title: "PasteJack",
            content: AccessibilityOnboardingView(onDismiss: { [weak self] in
                self?.onboardingWindow?.close()
            })
        )
    }

    // MARK: - Status Icon

    private func updateStatusIcon(for state: TypingSession.State) {
        let settings = UserSettings.shared

        // Show/hide typing overlay
        switch state {
        case .countdown, .typing:
            showTypingOverlay()
        case .completed, .cancelled, .error, .idle:
            hideTypingOverlay()
        }

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
            if settings.showNotification {
                sendCompletionNotification()
            }
            if let typedText = session.lastTypedText {
                TypingHistory.shared.add(text: typedText)
                settings.totalPasteCount += 1
                settings.totalCharsTyped += typedText.count
            }
            LicenseManager.shared.recordUsage()
            Task {
                try? await Task.sleep(for: .seconds(1))
                if LicenseManager.shared.shouldShowNag() {
                    showSupportNag()
                }
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

    // MARK: - Completion Notification

    private func sendCompletionNotification() {
        let content = UNMutableNotificationContent()
        content.title = "PasteJack"
        content.body = "Done — typing complete"
        content.sound = nil // Sound is handled by playSoundOnComplete

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Typing Overlay

    private func showTypingOverlay() {
        guard typingOverlayWindow == nil else { return }

        let window = NSWindow(
            contentRect: .zero,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.level = .statusBar
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.contentView = NSHostingView(rootView: TypingOverlayView(session: session))

        // Position bottom-center above Dock
        if let screen = NSScreen.main {
            let overlayWidth: CGFloat = 340
            let overlayHeight: CGFloat = 100
            let x = screen.frame.midX - overlayWidth / 2
            let y = screen.frame.origin.y + 80
            window.setFrame(NSRect(x: x, y: y, width: overlayWidth, height: overlayHeight), display: true)
        }

        window.orderFront(nil)
        self.typingOverlayWindow = window

        // Monitor Escape key to cancel typing
        escapeMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Escape
                Task { @MainActor in
                    self?.cancelTyping()
                }
            }
        }
    }

    private func hideTypingOverlay() {
        typingOverlayWindow?.orderOut(nil)
        typingOverlayWindow = nil

        if let escapeMonitor {
            NSEvent.removeMonitor(escapeMonitor)
        }
        escapeMonitor = nil
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let showOnboarding = Notification.Name("PasteJack.showOnboarding")
}
