import Foundation

/// A single typing history entry.
struct TypingHistoryEntry: Codable, Identifiable {
    let id: UUID
    let preview: String
    let fullText: String
    let charCount: Int
    let timestamp: Date

    init(text: String) {
        self.id = UUID()
        self.preview = String(text.prefix(80))
        self.fullText = text
        self.charCount = text.count
        self.timestamp = Date()
    }

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

/// Stores recent typing sessions. Max 10 entries, auto-purges after 24h.
@MainActor
final class TypingHistory: ObservableObject {

    static let shared = TypingHistory()

    @Published private(set) var entries: [TypingHistoryEntry] = []

    private let maxEntries = 10
    private let maxAgeSeconds: TimeInterval = 24 * 60 * 60 // 24 hours
    private let fileURL: URL

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("PasteJack", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("typing-history.json")
        load()
        purgeOld()
    }

    func add(text: String) {
        let entry = TypingHistoryEntry(text: text)
        entries.insert(entry, at: 0)
        if entries.count > maxEntries {
            entries = Array(entries.prefix(maxEntries))
        }
        save()
    }

    func remove(id: UUID) {
        entries.removeAll { $0.id == id }
        save()
    }

    func clear() {
        entries.removeAll()
        save()
    }

    private func purgeOld() {
        let cutoff = Date().addingTimeInterval(-maxAgeSeconds)
        entries.removeAll { $0.timestamp < cutoff }
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([TypingHistoryEntry].self, from: data) else { return }
        entries = decoded
    }
}
