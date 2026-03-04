import SwiftUI

/// Floating HUD displayed during typing sessions showing progress and cancel hint.
struct TypingOverlayView: View {

    @ObservedObject var session: TypingSession

    var body: some View {
        VStack(spacing: 8) {
            switch session.state {
            case .countdown(let remaining):
                HStack(spacing: 8) {
                    Image(systemName: "timer")
                        .font(.system(size: 14))
                        .foregroundStyle(.yellow)
                    Text("Starting in \(remaining)…")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(.primary)
                }

            case .typing(let progress, let current, let total):
                HStack(spacing: 8) {
                    Image(systemName: "keyboard.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.indigo)
                    Text("Typing \(current.formatted()) / \(total.formatted())")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(.primary)
                }

                ProgressView(value: progress)
                    .tint(.indigo)

            default:
                EmptyView()
            }

            Text("Press Esc to cancel")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .frame(width: 300)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(.quaternary, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.2), radius: 12, y: 4)
    }
}
