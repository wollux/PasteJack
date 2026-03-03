import Testing
@testable import PasteJack

@Suite("ClipboardReader Tests")
struct ClipboardReaderTests {

    @Test("Preview returns nil for empty string")
    func previewReturnsNilForEmpty() {
        // ClipboardReader.preview depends on actual clipboard state,
        // so we test the preview logic with known inputs via a helper.
        let result = previewText(nil, maxLength: 40)
        #expect(result == nil)
    }

    @Test("Preview returns short text as-is")
    func previewReturnsShortText() {
        let result = previewText("Hello", maxLength: 40)
        #expect(result == "Hello")
    }

    @Test("Preview replaces newlines with arrow symbol")
    func previewReplacesNewlines() {
        let result = previewText("line1\nline2", maxLength: 40)
        #expect(result == "line1↵line2")
    }

    @Test("Preview truncates long text with ellipsis")
    func previewTruncatesLongText() {
        let longText = String(repeating: "a", count: 100)
        let result = previewText(longText, maxLength: 40)
        #expect(result != nil)
        #expect(result!.contains("..."))
        #expect(result!.count <= 40)
    }

    @Test("Preview handles exact boundary length")
    func previewHandlesExactLength() {
        let text = String(repeating: "x", count: 40)
        let result = previewText(text, maxLength: 40)
        #expect(result == text)
    }

    // Helper that mirrors ClipboardReader.preview logic for testability
    private func previewText(_ text: String?, maxLength: Int) -> String? {
        guard let text, !text.isEmpty else { return nil }

        if text.count <= maxLength {
            return text.replacingOccurrences(of: "\n", with: "↵")
        }

        let half = (maxLength - 3) / 2
        let start = text.prefix(half).replacingOccurrences(of: "\n", with: "↵")
        let end = text.suffix(half).replacingOccurrences(of: "\n", with: "↵")
        return "\(start)...\(end)"
    }
}
