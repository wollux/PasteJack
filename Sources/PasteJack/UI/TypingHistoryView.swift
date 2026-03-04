import SwiftUI

/// Full window view for browsing and copying from typing history.
struct TypingHistoryView: View {

    @ObservedObject private var history = TypingHistory.shared
    @State private var selectedID: UUID?
    @State private var copiedToClipboard = false

    let onTypeEntry: (String) -> Void

    private var selectedEntry: TypingHistoryEntry? {
        guard let id = selectedID else { return nil }
        return history.entries.first { $0.id == id }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            HSplitView {
                entryList
                    .frame(minWidth: 200, idealWidth: 240)
                detailPanel
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
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(.white.opacity(0.9))

                VStack(alignment: .leading, spacing: 1) {
                    Text("Typing History")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("\(history.entries.count) entr\(history.entries.count == 1 ? "y" : "ies")")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                if !history.entries.isEmpty {
                    Button {
                        history.clear()
                        selectedID = nil
                    } label: {
                        Text("Clear All")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 50)
    }

    // MARK: - List

    private var entryList: some View {
        List(selection: $selectedID) {
            ForEach(history.entries) { entry in
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.preview)
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(2)
                    HStack(spacing: 6) {
                        Text("\(entry.charCount) chars")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.tertiary)
                        Spacer()
                        Text(entry.timeAgo)
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.vertical, 3)
                .tag(entry.id)
            }
        }
        .listStyle(.sidebar)
    }

    // MARK: - Detail Panel

    private var detailPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let entry = selectedEntry {
                HStack(spacing: 6) {
                    Text("\(entry.charCount) chars")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.quaternary)
                    Text("\u{00B7}")
                        .foregroundStyle(.quaternary)
                    Text(entry.timeAgo)
                        .font(.system(size: 10))
                        .foregroundStyle(.quaternary)
                    Spacer()
                }

                // Read-only selectable text view
                ScrollView {
                    Text(entry.fullText)
                        .font(.system(size: 12, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                }
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.textBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(.quaternary, lineWidth: 0.5)
                        )
                )

                HStack {
                    Button {
                        history.remove(id: entry.id)
                        selectedID = history.entries.first?.id
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .controlSize(.small)
                    .tint(.red)

                    Spacer()

                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(entry.fullText, forType: .string)
                        withAnimation(.easeInOut(duration: 0.2)) {
                            copiedToClipboard = true
                        }
                        Task {
                            try? await Task.sleep(for: .seconds(2))
                            withAnimation { copiedToClipboard = false }
                        }
                    } label: {
                        Label(copiedToClipboard ? "Copied" : "Copy All", systemImage: copiedToClipboard ? "checkmark" : "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                    .tint(copiedToClipboard ? .green : nil)
                    .controlSize(.small)

                    Button {
                        onTypeEntry(entry.fullText)
                    } label: {
                        Label("Type It", systemImage: "keyboard")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                    .controlSize(.small)
                }
            } else {
                Spacer()
                Text(history.entries.isEmpty ? "No typing history yet" : "Select an entry to view")
                    .font(.system(size: 13))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
                Spacer()
            }
        }
        .padding(14)
    }
}
