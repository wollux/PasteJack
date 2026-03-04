import Foundation

/// A single OCR history entry.
struct OCRHistoryEntry: Codable, Identifiable {
    let id: UUID
    let text: String
    let charCount: Int
    let timestamp: Date
    let detectedLanguages: [String]

    init(text: String, detectedLanguages: [String] = []) {
        self.id = UUID()
        self.text = text
        self.charCount = text.count
        self.timestamp = Date()
        self.detectedLanguages = detectedLanguages
    }

    var preview: String {
        String(text.prefix(80))
    }

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

/// Stores OCR results for quick re-use. Max 20 entries, persisted to disk.
@MainActor
final class OCRHistory: ObservableObject {

    static let shared = OCRHistory()

    @Published private(set) var entries: [OCRHistoryEntry] = []

    private let maxEntries = 20
    private let fileURL: URL

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("PasteJack", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("ocr-history.json")
        load()
    }

    func add(text: String, detectedLanguages: [String] = []) {
        let entry = OCRHistoryEntry(text: text, detectedLanguages: detectedLanguages)
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

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([OCRHistoryEntry].self, from: data) else { return }
        entries = decoded
    }
}
