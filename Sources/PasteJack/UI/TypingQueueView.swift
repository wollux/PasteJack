import SwiftUI

/// Window for building and executing a typing queue.
struct TypingQueueView: View {

    @ObservedObject var queue: TypingQueue
    @ObservedObject var session: TypingSession
    let onExecute: () -> Void
    let onCancel: () -> Void

    @State private var editingItemID: UUID?
    @State private var editText = ""

    var body: some View {
        VStack(spacing: 0) {
            header
            queueList
            footer
        }
        .frame(width: 440, height: 500)
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
                Image(systemName: "list.bullet.rectangle")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(.white.opacity(0.9))

                VStack(alignment: .leading, spacing: 1) {
                    Text("Typing Queue")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("\(queue.items.count) item\(queue.items.count == 1 ? "" : "s")")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                HStack(spacing: 8) {
                    Button {
                        queue.addFromClipboard()
                    } label: {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 13))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .help("Add from Clipboard")

                    Button {
                        queue.addEmpty()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .help("Add Empty Item")
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 50)
    }

    // MARK: - Queue List

    private var queueList: some View {
        Group {
            if queue.items.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 36))
                        .foregroundStyle(.quaternary)
                    Text("No items in queue")
                        .font(.system(size: 13))
                        .foregroundStyle(.tertiary)
                    Text("Add items from clipboard or type manually")
                        .font(.system(size: 11))
                        .foregroundStyle(.quaternary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List {
                    ForEach(Array(queue.items.enumerated()), id: \.element.id) { index, item in
                        queueRow(item: item, index: index)
                    }
                    .onMove { source, destination in
                        queue.move(from: source, to: destination)
                    }
                    .onDelete { offsets in
                        for offset in offsets {
                            queue.remove(id: queue.items[offset].id)
                        }
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
    }

    private func queueRow(item: QueueItem, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                // Index badge
                Text("\(index + 1)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .background(
                        Circle().fill(
                            queue.isRunning && queue.currentIndex == index
                                ? Color.indigo
                                : Color.secondary.opacity(0.4)
                        )
                    )

                if editingItemID == item.id {
                    TextField("Text to type", text: $editText, onCommit: {
                        if let idx = queue.items.firstIndex(where: { $0.id == item.id }) {
                            queue.items[idx].text = editText
                        }
                        editingItemID = nil
                    })
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 11, design: .monospaced))
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.text.isEmpty ? "(empty)" : item.preview)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(item.text.isEmpty ? .tertiary : .primary)
                            .lineLimit(1)

                        Text("\(item.text.count) chars")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(.quaternary)
                    }
                    .onTapGesture {
                        editingItemID = item.id
                        editText = item.text
                    }
                }

                Spacer()

                // Separator picker
                Picker("", selection: Binding(
                    get: { item.separator },
                    set: { newValue in
                        if let idx = queue.items.firstIndex(where: { $0.id == item.id }) {
                            queue.items[idx].separator = newValue
                        }
                    }
                )) {
                    Text("--").tag("none")
                    Text("\u{21E5}").tag("tab")
                    Text("\u{21A9}").tag("enter")
                    Text("\u{21E5}\u{21A9}").tag("tabEnter")
                    Text("0.5s").tag("delay500")
                }
                .frame(width: 60)
                .controlSize(.mini)
                .help("Separator after this item")
            }
        }
        .padding(.vertical, 2)
        .background(
            queue.isRunning && queue.currentIndex == index
                ? Color.indigo.opacity(0.08)
                : Color.clear
        )
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 10) {
            Button {
                queue.clear()
            } label: {
                Label("Clear", systemImage: "trash")
            }
            .controlSize(.small)
            .disabled(queue.items.isEmpty || queue.isRunning)

            Spacer()

            if queue.isRunning {
                Button {
                    onCancel()
                    queue.stop()
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.small)
            } else {
                Button {
                    onExecute()
                } label: {
                    Label("Type All", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
                .controlSize(.small)
                .disabled(queue.items.isEmpty)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial)
    }
}
