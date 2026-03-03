import AppKit

/// Reads text content from the system clipboard.
enum ClipboardReader {

    /// Read the current clipboard contents as a string.
    /// Returns nil if the clipboard is empty or contains no string data.
    static func readString() -> String? {
        NSPasteboard.general.string(forType: .string)
    }

    /// Check if the clipboard contains text content.
    static var hasText: Bool {
        NSPasteboard.general.availableType(from: [.string]) != nil
    }

    /// Get a preview of the clipboard contents.
    /// Shows first and last characters with ellipsis in between for long text.
    static func preview(maxLength: Int = 40) -> String? {
        guard let text = readString(), !text.isEmpty else { return nil }

        if text.count <= maxLength {
            return text.replacingOccurrences(of: "\n", with: "↵")
        }

        let half = (maxLength - 3) / 2
        let start = text.prefix(half).replacingOccurrences(of: "\n", with: "↵")
        let end = text.suffix(half).replacingOccurrences(of: "\n", with: "↵")
        return "\(start)...\(end)"
    }

    /// Get the character count of the clipboard contents.
    static var characterCount: Int {
        readString()?.count ?? 0
    }
}
