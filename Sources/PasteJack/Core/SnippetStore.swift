import Foundation

/// A saved text snippet.
struct Snippet: Codable, Identifiable {
    let id: UUID
    var name: String
    var text: String
    let createdAt: Date
    var modifiedAt: Date

    init(name: String, text: String) {
        self.id = UUID()
        self.name = name
        self.text = text
        self.createdAt = Date()
        self.modifiedAt = Date()
    }

    // Custom decoder to handle migration from old format without modifiedAt
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        text = try container.decode(String.self, forKey: .text)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        modifiedAt = try container.decodeIfPresent(Date.self, forKey: .modifiedAt) ?? createdAt
    }

    var charCount: Int { text.count }
}

/// Manages a persistent library of text snippets with optional iCloud sync.
@MainActor
final class SnippetStore: ObservableObject {

    static let shared = SnippetStore()

    @Published private(set) var snippets: [Snippet] = []

    private let fileURL: URL
    private static let iCloudKey = "snippets"

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("PasteJack", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("snippets.json")
        load()
        setupICloudObserver()
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
        snippets[index].modifiedAt = Date()
        save()
    }

    func remove(id: UUID) {
        snippets.removeAll { $0.id == id }
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(snippets) else { return }
        try? data.write(to: fileURL, options: .atomic)
        syncToICloud()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([Snippet].self, from: data) else { return }
        snippets = decoded
    }

    // MARK: - iCloud Sync

    private func setupICloudObserver() {
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.mergeFromICloud()
            }
        }
        NSUbiquitousKeyValueStore.default.synchronize()
    }

    private func syncToICloud() {
        guard UserSettings.shared.iCloudSyncEnabled else { return }
        guard let data = try? JSONEncoder().encode(snippets) else { return }
        NSUbiquitousKeyValueStore.default.set(data, forKey: Self.iCloudKey)
        NSUbiquitousKeyValueStore.default.synchronize()
    }

    private func mergeFromICloud() {
        guard UserSettings.shared.iCloudSyncEnabled else { return }
        guard let data = NSUbiquitousKeyValueStore.default.data(forKey: Self.iCloudKey),
              let remoteSnippets = try? JSONDecoder().decode([Snippet].self, from: data) else { return }

        var merged = snippets
        for remote in remoteSnippets {
            if let localIndex = merged.firstIndex(where: { $0.id == remote.id }) {
                // Same UUID — keep the newer one
                if remote.modifiedAt > merged[localIndex].modifiedAt {
                    merged[localIndex] = remote
                }
            } else {
                // New snippet from remote
                merged.append(remote)
            }
        }

        // Sort by modifiedAt descending
        merged.sort { $0.modifiedAt > $1.modifiedAt }
        snippets = merged

        // Save locally
        guard let localData = try? JSONEncoder().encode(snippets) else { return }
        try? localData.write(to: fileURL, options: .atomic)
    }
}
