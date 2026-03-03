import SwiftUI

struct OCRResultView: View {

    @State var recognizedText: String
    @State private var autoCloseRemaining: Int
    @State private var isEditing = false
    @State private var timer: Timer?
    @State private var copiedToClipboard = false

    let onTypeIt: (String) -> Void
    let onTryAgain: () -> Void
    let onDismiss: () -> Void

    private let autoCloseEnabled: Bool

    init(
        text: String,
        onTypeIt: @escaping (String) -> Void,
        onTryAgain: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self._recognizedText = State(initialValue: text)
        let settings = UserSettings.shared
        self.autoCloseEnabled = settings.ocrAutoClose
        self._autoCloseRemaining = State(initialValue: settings.ocrAutoCloseSeconds)
        self.onTypeIt = onTypeIt
        self.onTryAgain = onTryAgain
        self.onDismiss = onDismiss
    }

    var body: some View {
        VStack(spacing: 0) {
            gradientHeader
            content
            footerButtons
        }
        .frame(width: 480, height: 420)
        .background(Color(.windowBackgroundColor))
        .onAppear { startAutoClose() }
        .onDisappear { timer?.invalidate() }
    }

    // MARK: - Header

    private var gradientHeader: some View {
        ZStack {
            LinearGradient(
                colors: [.teal, .cyan, .blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 8) {
                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 32, weight: .thin))
                    .foregroundStyle(.white.opacity(0.9))

                Text("Text Captured")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(.vertical, 16)
        }
        .frame(height: 100)
        .clipShape(UnevenRoundedRectangle(
            topLeadingRadius: 0,
            bottomLeadingRadius: 20,
            bottomTrailingRadius: 20,
            topTrailingRadius: 0
        ))
    }

    // MARK: - Content

    private var content: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Text editor card
            VStack(alignment: .leading, spacing: 8) {
                Label("Recognized Text", systemImage: "text.quote")
                    .font(.headline)

                TextEditor(text: $recognizedText)
                    .font(.system(.body, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.textBackgroundColor))
                    )
                    .frame(minHeight: 100, maxHeight: 180)
                    .onChange(of: recognizedText) {
                        isEditing = true
                        copiedToClipboard = false
                    }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.06), radius: 4, y: 2)

            // Clipboard status
            HStack(spacing: 6) {
                if copiedToClipboard {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Copied to clipboard")
                        .foregroundStyle(.green)
                        .font(.callout)
                }

                Spacer()

                if autoCloseEnabled && !isEditing && autoCloseRemaining > 0 {
                    Text("Closes in \(autoCloseRemaining)s")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    // MARK: - Footer

    private var footerButtons: some View {
        HStack(spacing: 12) {
            Button("Try Again") {
                timer?.invalidate()
                onTryAgain()
            }
            .controlSize(.large)

            Spacer()

            Button("Done") {
                timer?.invalidate()
                onDismiss()
            }
            .controlSize(.large)

            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(recognizedText, forType: .string)
                withAnimation(.easeInOut(duration: 0.3)) {
                    copiedToClipboard = true
                }
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button {
                timer?.invalidate()
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(recognizedText, forType: .string)
                onTypeIt(recognizedText)
            } label: {
                Label("Type It", systemImage: "keyboard")
            }
            .controlSize(.large)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
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
