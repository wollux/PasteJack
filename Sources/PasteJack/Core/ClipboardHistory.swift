import AppKit
import Foundation

/// Monitors the clipboard and keeps a history of recent entries for quick-paste.
@MainActor
final class ClipboardHistory: ObservableObject {

    static let shared = ClipboardHistory()

    @Published private(set) var entries: [ClipboardEntry] = []
    private var lastChangeCount = 0
    private var timer: Timer?

    static let maxEntries = 5

    struct ClipboardEntry: Identifiable {
        let id = UUID()
        let text: String
        let timestamp: Date

        var preview: String {
            String(text.prefix(60)).replacingOccurrences(of: "\n", with: " ")
        }
    }

    private init() {
        lastChangeCount = NSPasteboard.general.changeCount
    }

    func startMonitoring() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkClipboard()
            }
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func checkClipboard() {
        let currentCount = NSPasteboard.general.changeCount
        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount

        guard let text = NSPasteboard.general.string(forType: .string),
              !text.isEmpty else { return }

        // Don't add duplicates of the most recent entry
        if entries.first?.text == text { return }

        entries.insert(ClipboardEntry(text: text, timestamp: Date()), at: 0)
        if entries.count > Self.maxEntries {
            entries.removeLast()
        }
    }
}
