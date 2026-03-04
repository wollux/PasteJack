import SwiftUI

/// Full window view for managing text snippets.
struct SnippetLibraryView: View {

    @ObservedObject private var store = SnippetStore.shared
    @State private var selectedID: UUID?
    @State private var editName = ""
    @State private var editText = ""
    @State private var searchText = ""

    let onTypeSnippet: (String) -> Void

    private var filteredSnippets: [Snippet] {
        if searchText.isEmpty {
            return store.snippets
        }
        return store.snippets.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.text.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            HSplitView {
                snippetList
                    .frame(minWidth: 200, idealWidth: 240)
                editorPanel
                    .frame(minWidth: 300)
            }
        }
        .frame(width: 640, height: 440)
        .background(Color(.windowBackgroundColor))
    }

    // MARK: - Header

    private var header: some View {
        ZStack(alignment: .leading) {
            LinearGradient(
                colors: [
                    Color(red: 0.26, green: 0.22, blue: 0.79),
                    Color(red: 0.15, green: 0.39, blue: 0.92),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            HStack(spacing: 14) {
                Image(systemName: "doc.text")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(.white.opacity(0.9))

                VStack(alignment: .leading, spacing: 1) {
                    Text("Snippet Library")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("\(store.snippets.count) snippet\(store.snippets.count == 1 ? "" : "s")")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                Button {
                    store.add(name: "New Snippet", text: "")
                    if let first = store.snippets.first {
                        selectSnippet(first)
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 50)
    }

    // MARK: - List

    private var snippetList: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
                TextField("Search…", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color(.textBackgroundColor))

            Divider()

            List(selection: $selectedID) {
                ForEach(filteredSnippets) { snippet in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(snippet.name)
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)
                        Text("\(snippet.charCount) chars")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 3)
                    .tag(snippet.id)
                }
                .onDelete { offsets in
                    for offset in offsets {
                        store.remove(id: filteredSnippets[offset].id)
                    }
                }
            }
            .listStyle(.sidebar)
            .onChange(of: selectedID) {
                if let id = selectedID, let snippet = store.snippets.first(where: { $0.id == id }) {
                    editName = snippet.name
                    editText = snippet.text
                }
            }
        }
    }

    // MARK: - Editor

    private var editorPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            if selectedID != nil {
                TextField("Name", text: $editName)
                    .font(.system(size: 14, weight: .medium))
                    .textFieldStyle(.roundedBorder)

                TextEditor(text: $editText)
                    .font(.system(size: 12, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.textBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .strokeBorder(.quaternary, lineWidth: 0.5)
                            )
                    )

                HStack {
                    Text("\(editText.count) chars")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.quaternary)

                    Spacer()

                    Button("Save") {
                        if let id = selectedID {
                            store.update(id: id, name: editName, text: editText)
                        }
                    }
                    .controlSize(.small)

                    Button("Delete") {
                        if let id = selectedID {
                            store.remove(id: id)
                            selectedID = store.snippets.first?.id
                        }
                    }
                    .controlSize(.small)
                    .tint(.red)

                    Button {
                        onTypeSnippet(editText)
                    } label: {
                        Label("Type It", systemImage: "keyboard")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                    .controlSize(.small)
                    .disabled(editText.isEmpty)
                }
            } else {
                Spacer()
                Text("Select a snippet or create one")
                    .font(.system(size: 13))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
                Spacer()
            }
        }
        .padding(14)
    }

    private func selectSnippet(_ snippet: Snippet) {
        selectedID = snippet.id
        editName = snippet.name
        editText = snippet.text
    }
}
