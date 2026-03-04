import Foundation

/// A saved text snippet.
struct Snippet: Codable, Identifiable {
    let id: UUID
    var name: String
    var text: String
    let createdAt: Date

    init(name: String, text: String) {
        self.id = UUID()
        self.name = name
        self.text = text
        self.createdAt = Date()
    }

    var charCount: Int { text.count }
}

/// Manages a persistent library of text snippets.
@MainActor
final class SnippetStore: ObservableObject {

    static let shared = SnippetStore()

    @Published private(set) var snippets: [Snippet] = []

    private let fileURL: URL

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("PasteJack", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("snippets.json")
        load()
    }

    func add(name: String, text: String) {
        let snippet = Snippet(name: name, text: text)
        snippets.insert(snippet, at: 0)
        save()
    }

    func update(id: UUID, name: String, text: String) {
        guard let index = snippets.firstIndex(where: { $0.id == id }) else { return }
        snippets[index].name = name
        snippets[index].text = text
        save()
    }

    func remove(id: UUID) {
        snippets.removeAll { $0.id == id }
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(snippets) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([Snippet].self, from: data) else { return }
        snippets = decoded
    }
}
