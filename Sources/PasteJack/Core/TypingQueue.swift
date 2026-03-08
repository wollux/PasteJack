import AppKit
import Foundation

/// A single item in the typing queue.
struct QueueItem: Codable, Identifiable {
    let id: UUID
    var text: String
    var separator: String  // "none", "tab", "enter", "tabEnter", "delay500"

    init(text: String, separator: String = "tab") {
        self.id = UUID()
        self.text = text
        self.separator = separator
    }

    var preview: String {
        String(text.prefix(60)).replacingOccurrences(of: "\n", with: " ")
    }
}

/// Manages and executes a queue of text items to type sequentially.
@MainActor
final class TypingQueue: ObservableObject {

    @Published var items: [QueueItem] = []
    @Published var currentIndex: Int = -1
    @Published var isRunning: Bool = false

    func addFromClipboard() {
        guard let text = NSPasteboard.general.string(forType: .string),
              !text.isEmpty else { return }
        items.append(QueueItem(text: text))
    }

    func addText(_ text: String) {
        guard !text.isEmpty else { return }
        items.append(QueueItem(text: text))
    }

    func addEmpty() {
        items.append(QueueItem(text: ""))
    }

    func remove(id: UUID) {
        items.removeAll { $0.id == id }
    }

    func move(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
    }

    func clear() {
        items.removeAll()
        currentIndex = -1
        isRunning = false
    }

    /// Execute the queue: type each item, send separator, next item.
    func execute(session: TypingSession, settings: UserSettings) async {
        guard !items.isEmpty else { return }
        isRunning = true

        let targetLayout = TargetLayout(rawValue: settings.targetLayout) ?? .auto

        for (index, item) in items.enumerated() {
            if !isRunning { break }
            currentIndex = index

            guard !item.text.isEmpty else { continue }

            // Map separator to postTypingAction — only Tab/Enter values
            let postAction: String
            switch item.separator {
            case "tab", "enter", "tabEnter":
                postAction = item.separator
            default:
                postAction = "none"
            }

            session.start(
                text: item.text,
                delayMicroseconds: settings.delayMicroseconds,
                countdownSeconds: index == 0 ? settings.countdownSeconds : 0,
                adaptiveSpeed: settings.adaptiveSpeed,
                lineDelayMicroseconds: settings.lineDelayMicroseconds,
                postTypingAction: postAction,
                targetLayout: targetLayout
            )

            // Wait for session to complete
            while session.isActive {
                try? await Task.sleep(for: .milliseconds(100))
            }

            // Check if cancelled or errored
            switch session.state {
            case .cancelled:
                isRunning = false
                return
            case .error:
                isRunning = false
                return
            default:
                break
            }

            // Extra delay between items for delay500 separator
            if index < items.count - 1 && item.separator == "delay500" {
                try? await Task.sleep(for: .milliseconds(500))
            }
        }

        currentIndex = -1
        isRunning = false
    }

    func stop() {
        isRunning = false
    }
}
