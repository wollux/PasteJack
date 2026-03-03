import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private let hotkeyManager = HotkeyManager()
    private let session = TypingSession()
    private var cancellable: Any?
    private var settingsWindow: NSWindow?
    private var onboardingWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide Dock icon — menu bar only
        NSApp.setActivationPolicy(.accessory)

        setupStatusItem()

        // Show onboarding window if Accessibility permission is missing
        if !AccessibilityChecker.hasPermission {
            showOnboarding()
        }

        // Register global hotkey (Ctrl+Shift+V)
        hotkeyManager.register { [weak self] in
            Task { @MainActor in
                self?.handleHotkey()
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
        }

        let menu = NSMenu()

        let pasteItem = NSMenuItem(
            title: "Paste as Keystrokes (⌃⇧V)",
            action: #selector(handleHotkey),
            keyEquivalent: ""
        )
        pasteItem.target = self
        menu.addItem(pasteItem)

        let cancelItem = NSMenuItem(
            title: "Cancel Typing",
            action: #selector(cancelTyping),
            keyEquivalent: ""
        )
        cancelItem.target = self
        menu.addItem(cancelItem)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(
            title: "Settings\u{2026}",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(
            title: "Quit PasteJack",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))

        menu.delegate = self
        statusItem.menu = menu
    }

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

    private func updateStatusIcon(for state: TypingSession.State) {
        let settings = UserSettings.shared

        // If showProgress is off, keep icon at idle (except errors)
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
            // Play completion sound
            if settings.playSoundOnComplete {
                NSSound(named: "Glass")?.play()
            }
            // Reset to idle after a short delay
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

// MARK: - NSMenuDelegate

extension AppDelegate: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        if let cancelItem = menu.items.first(where: { $0.action == #selector(cancelTyping) }) {
            cancelItem.isHidden = !session.isActive
        }
        if let pasteItem = menu.items.first(where: { $0.action == #selector(handleHotkey) }) {
            pasteItem.isEnabled = !session.isActive

            if let preview = ClipboardReader.preview() {
                pasteItem.toolTip = preview
            }
        }
    }
}
