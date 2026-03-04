import SwiftUI

/// Preview window shown before typing, displaying text stats and estimated time.
struct TypingPreviewView: View {

    let text: String
    let delayMs: Double
    let onStart: () -> Void
    let onCancel: () -> Void

    private var charCount: Int { text.count }
    private var lineCount: Int { text.components(separatedBy: "\n").count }
    private var wordCount: Int { text.split(whereSeparator: \.isWhitespace).count }

    private var estimatedSeconds: Double {
        Double(charCount) * delayMs / 1000.0
    }

    private var estimatedTimeString: String {
        if estimatedSeconds < 1 {
            return "< 1s"
        } else if estimatedSeconds < 60 {
            return "\(Int(estimatedSeconds))s"
        } else {
            let mins = Int(estimatedSeconds) / 60
            let secs = Int(estimatedSeconds) % 60
            return "\(mins)m \(secs)s"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            textPreview
            statsRow
            actionBar
        }
        .frame(width: 480)
        .background(Color(.windowBackgroundColor))
    }

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
                Image(systemName: "eye")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(.white.opacity(0.9))

                VStack(alignment: .leading, spacing: 1) {
                    Text("Typing Preview")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("\(charCount) chars \u{00B7} ~\(estimatedTimeString)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 56)
    }

    private var textPreview: some View {
        ScrollView {
            Text(text)
                .font(.system(size: 12, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
        }
        .frame(maxHeight: 200)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.textBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(.quaternary, lineWidth: 0.5)
                )
        )
        .padding(.horizontal, 16)
        .padding(.top, 14)
    }

    private var statsRow: some View {
        HStack(spacing: 16) {
            statLabel("Lines", value: "\(lineCount)")
            statLabel("Words", value: "\(wordCount)")
            statLabel("Chars", value: "\(charCount.formatted())")
            statLabel("Est. Time", value: estimatedTimeString)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func statLabel(_ label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.indigo)
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(.quaternary)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
    }

    private var actionBar: some View {
        HStack {
            Button("Cancel") {
                onCancel()
            }
            .controlSize(.regular)

            Spacer()

            Button {
                onStart()
            } label: {
                Label("Start Typing", systemImage: "keyboard")
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
            .controlSize(.regular)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
