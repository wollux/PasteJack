import SwiftUI

/// Custom popover menu displayed when clicking the menu bar icon.
struct MenuBarView: View {

    @ObservedObject var session: TypingSession
    let onPaste: () -> Void
    let onOCR: () -> Void
    let onSelectedText: () -> Void
    let onMultiOCR: () -> Void
    let onCancel: () -> Void
    let onSettings: () -> Void
    let onSnippets: () -> Void
    let onQuit: () -> Void
    let dismissPopover: () -> Void
    let onTypingHistory: () -> Void
    let onOCRHistory: () -> Void

    @State private var hoveredItem: String?

    var body: some View {
        VStack(spacing: 0) {
            statusSection
            menuDivider
            actionItems
            menuDivider
            historyAndSnippetItems
            menuDivider
            quitItem
        }
        .frame(width: 260)
        .background(Color(.windowBackgroundColor))
    }

    // MARK: - Status Section

    @ViewBuilder
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            switch session.state {
            case .idle:
                HStack(spacing: 8) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                    if let charCount = ClipboardReader.optionalCharacterCount {
                        Text("Ready \u{2014} clipboard: \(charCount) chars")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Ready \u{2014} clipboard empty")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }

            case .countdown(let remaining):
                HStack(spacing: 8) {
                    Image(systemName: "timer")
                        .font(.system(size: 14))
                        .foregroundStyle(.yellow)
                    Text("Starting in ")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.yellow)
                    + Text("\(remaining)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(.yellow)
                    + Text("\u{2026}")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.yellow)
                }

            case .typing(let progress, let current, let total):
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "keyboard.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.indigo)
                        Text("Typing \(current) / \(total) chars")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.indigo)
                    }
                    ProgressView(value: progress)
                        .tint(.indigo)
                }

            case .completed:
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.green)
                    Text("Done! chars typed")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.green)
                }

            case .cancelled:
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 14))
                        .foregroundStyle(.orange)
                    Text("Cancelled")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.orange)
                }

            case .error(let message):
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.red)
                    Text(message)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.red)
                        .lineLimit(2)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - Action Items

    private var actionItems: some View {
        VStack(spacing: 0) {
            menuItem(
                id: "paste",
                icon: "keyboard",
                label: "Paste as Keystrokes",
                shortcut: "⌃⇧V",
                disabled: session.isActive
            ) {
                dismissPopover()
                onPaste()
            }

            menuItem(
                id: "ocr",
                icon: "doc.text.viewfinder",
                label: "Copy from Screen",
                shortcut: "⌃⇧C",
                disabled: session.isActive
            ) {
                dismissPopover()
                onOCR()
            }

            menuItem(
                id: "selected",
                icon: "text.cursor",
                label: "Type Selected Text",
                shortcut: "⌃⇧T",
                disabled: session.isActive
            ) {
                dismissPopover()
                onSelectedText()
            }

            menuItem(
                id: "multi-ocr",
                icon: "rectangle.stack",
                label: "Multi-Region OCR",
                shortcut: nil,
                disabled: session.isActive
            ) {
                dismissPopover()
                onMultiOCR()
            }

            if session.isActive {
                menuItem(
                    id: "cancel",
                    icon: "xmark.circle",
                    label: "Cancel Typing",
                    shortcut: nil,
                    tintColor: .red
                ) {
                    onCancel()
                }
            }
        }
    }

    // MARK: - History, Snippets & Settings

    private var historyAndSnippetItems: some View {
        VStack(spacing: 0) {
            menuItem(
                id: "typing-history",
                icon: "clock.arrow.circlepath",
                label: "Typing History\u{2026}",
                shortcut: nil
            ) {
                dismissPopover()
                onTypingHistory()
            }

            menuItem(
                id: "ocr-history",
                icon: "doc.text.viewfinder",
                label: "OCR History\u{2026}",
                shortcut: nil
            ) {
                dismissPopover()
                onOCRHistory()
            }

            menuItem(
                id: "snippets",
                icon: "doc.text",
                label: "Snippet Library\u{2026}",
                shortcut: nil
            ) {
                dismissPopover()
                onSnippets()
            }

            menuItem(
                id: "settings",
                icon: "gearshape",
                label: "Settings\u{2026}",
                shortcut: "\u{2318},"
            ) {
                dismissPopover()
                onSettings()
            }
        }
    }

    // MARK: - Quit

    private var quitItem: some View {
        menuItem(
            id: "quit",
            icon: "xmark.circle",
            label: "Quit PasteJack",
            shortcut: "\u{2318}Q",
            tintColor: .secondary
        ) {
            onQuit()
        }
    }

    // MARK: - Menu Item

    private func menuItem(
        id: String,
        icon: String,
        label: String,
        shortcut: String?,
        tintColor: Color? = nil,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .frame(width: 18)
                    .foregroundStyle(tintColor ?? .primary)

                Text(label)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(tintColor ?? .primary)

                Spacer()

                if let shortcut {
                    Text(shortcut)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .background(
                hoveredItem == id
                    ? Color.indigo.opacity(0.15)
                    : Color.clear
            )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.4 : 1)
        .onHover { isHovered in
            hoveredItem = isHovered ? id : nil
        }
    }

    // MARK: - Divider

    private var menuDivider: some View {
        Divider()
            .padding(.vertical, 2)
    }
}

// MARK: - ClipboardReader Extension

extension ClipboardReader {
    /// Returns character count if clipboard has text, nil otherwise.
    static var optionalCharacterCount: Int? {
        guard let text = NSPasteboard.general.string(forType: .string), !text.isEmpty else {
            return nil
        }
        return text.count
    }
}
