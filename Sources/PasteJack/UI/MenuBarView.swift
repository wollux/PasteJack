import SwiftUI

/// SwiftUI view displayed inside the menu bar popover (future use).
/// Currently the menu is built with NSMenu in AppDelegate for reliability.
struct MenuBarView: View {

    @ObservedObject var session: TypingSession
    let onPaste: () -> Void
    let onCancel: () -> Void
    let onSettings: () -> Void
    let onQuit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            statusSection

            Divider()

            if session.isActive {
                Button("Cancel Typing") {
                    onCancel()
                }
                .keyboardShortcut(.escape, modifiers: [])
            } else {
                clipboardPreview
                Button("Paste as Keystrokes  ⌃⇧V") {
                    onPaste()
                }
            }

            Divider()

            Button("Settings...") {
                onSettings()
            }
            .keyboardShortcut(",", modifiers: .command)

            Button("Quit PasteJack") {
                onQuit()
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding(12)
        .frame(width: 260)
    }

    @ViewBuilder
    private var statusSection: some View {
        switch session.state {
        case .idle:
            Label("Ready", systemImage: "keyboard.badge.ellipsis")
                .foregroundStyle(.secondary)
        case .countdown(let remaining):
            Label("Starting in \(remaining)...", systemImage: "timer")
                .foregroundStyle(.orange)
        case .typing(let progress, let current, let total):
            VStack(alignment: .leading, spacing: 4) {
                Label("Typing \(current)/\(total)", systemImage: "keyboard.fill")
                ProgressView(value: progress)
            }
        case .completed:
            Label("Done!", systemImage: "checkmark.circle")
                .foregroundStyle(.green)
        case .cancelled:
            Label("Cancelled", systemImage: "xmark.circle")
                .foregroundStyle(.orange)
        case .error(let message):
            Label(message, systemImage: "exclamationmark.triangle")
                .foregroundStyle(.red)
        }
    }

    @ViewBuilder
    private var clipboardPreview: some View {
        if let preview = ClipboardReader.preview() {
            VStack(alignment: .leading, spacing: 2) {
                Text("Clipboard (\(ClipboardReader.characterCount) chars):")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(preview)
                    .font(.caption)
                    .lineLimit(2)
                    .foregroundStyle(.primary)
            }
        } else {
            Text("Clipboard empty")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
