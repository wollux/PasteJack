import SwiftUI

struct OCRResultView: View {

    @State var recognizedText: String
    @State private var autoCloseRemaining: Int
    @State private var isEditing = false
    @State private var timer: Timer?
    @State private var copiedToClipboard = false

    let detectedLanguages: [String]
    let onTypeIt: (String) -> Void
    let onTryAgain: () -> Void
    let onDismiss: () -> Void

    private let autoCloseEnabled: Bool

    init(
        text: String,
        detectedLanguages: [String] = [],
        onTypeIt: @escaping (String) -> Void,
        onTryAgain: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self._recognizedText = State(initialValue: text)
        self.detectedLanguages = detectedLanguages
        let settings = UserSettings.shared
        self.autoCloseEnabled = settings.ocrAutoClose
        self._autoCloseRemaining = State(initialValue: settings.ocrAutoCloseSeconds)
        self.onTypeIt = onTypeIt
        self.onTryAgain = onTryAgain
        self.onDismiss = onDismiss
    }

    private var lineCount: Int {
        recognizedText.components(separatedBy: "\n").count
    }

    private var charCount: Int {
        recognizedText.count
    }

    private var wordCount: Int {
        recognizedText.split(whereSeparator: \.isWhitespace).count
    }

    var body: some View {
        VStack(spacing: 0) {
            compactHeader
            editorContent
            statsGrid
            actionBar
        }
        .frame(width: 620, height: 480)
        .background(Color(.windowBackgroundColor))
        .onDisappear { timer?.invalidate() }
    }

    // MARK: - Compact Header

    private var compactHeader: some View {
        ZStack(alignment: .leading) {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.58, blue: 0.55),  // #0D9488
                    Color(red: 0.03, green: 0.57, blue: 0.70),  // #0891B2
                    Color(red: 0.11, green: 0.31, blue: 0.85),  // #1D4ED8
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack {
                LinearGradient(
                    colors: [.white.opacity(0.08), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 30)
                Spacer()
            }

            HStack(spacing: 14) {
                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 26, weight: .light))
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.3), radius: 6, y: 2)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Text Captured")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("\(lineCount) line\(lineCount != 1 ? "s" : "") \u{00B7} \(charCount) chars \u{00B7} Apple Vision OCR")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                // Language pills
                if !detectedLanguages.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(detectedLanguages.prefix(2), id: \.self) { lang in
                            Text(lang)
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(.white.opacity(0.15)))
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 56)
    }

    // MARK: - Editor Content

    private var editorContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "pencil")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                Text("EDIT TEXT")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .tracking(1.2)
            }
            .padding(.bottom, 8)

            TextEditor(text: $recognizedText)
                .font(.system(size: 13, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.textBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(.quaternary, lineWidth: 0.5)
                        )
                )
                .frame(minHeight: 140, maxHeight: 200)
                .onChange(of: recognizedText) {
                    isEditing = true
                    copiedToClipboard = false
                }

            // Char count + copy feedback
            HStack {
                Text("\(charCount) chars")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.quaternary)

                Spacer()

                if copiedToClipboard {
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                        Text("Copied")
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(.green)
                    .transition(.opacity)
                }
            }
            .padding(.top, 6)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        HStack(spacing: 6) {
            StatBox(label: "Lines", value: "\(lineCount)")
            StatBox(label: "Words", value: "\(wordCount)")
            StatBox(label: "Chars", value: "\(charCount)")
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: 8) {
            Button {
                timer?.invalidate()
                onTryAgain()
            } label: {
                Label("Try Again", systemImage: "arrow.counterclockwise")
            }
            .controlSize(.regular)

            Spacer()

            Button("Done") {
                timer?.invalidate()
                onDismiss()
            }
            .controlSize(.regular)

            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(recognizedText, forType: .string)
                withAnimation(.easeInOut(duration: 0.2)) {
                    copiedToClipboard = true
                }
            } label: {
                Label(copiedToClipboard ? "Copied" : "Copy", systemImage: copiedToClipboard ? "checkmark" : "doc.on.doc")
            }
            .buttonStyle(.bordered)
            .tint(copiedToClipboard ? .green : nil)
            .controlSize(.regular)

            Button {
                timer?.invalidate()
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(recognizedText, forType: .string)
                onTypeIt(recognizedText)
            } label: {
                Label("Type It", systemImage: "keyboard")
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
            .controlSize(.regular)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Auto Close

    private func startAutoClose() {
        guard autoCloseEnabled else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                guard !isEditing else { return }
                autoCloseRemaining -= 1
                if autoCloseRemaining <= 0 {
                    timer?.invalidate()
                    onDismiss()
                }
            }
        }
    }
}

// MARK: - Stat Box

private struct StatBox: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.indigo)

            Text(label.uppercased())
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(.quaternary)
                .tracking(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(.quaternary, lineWidth: 0.5)
        )
    }
}
