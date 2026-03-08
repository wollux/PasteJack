import SwiftUI

/// Compact floating HUD displayed during typing sessions — matches mockup style.
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
                    Text("Starting in ")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(.primary)
                    + Text("\(remaining)")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(.yellow)
                    + Text("\u{2026}")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(.primary)
                }

            case .typing(let progress, let current, let total):
                HStack(spacing: 8) {
                    Image(systemName: "keyboard.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.indigo)
                    Text("Typing \(current.formatted()) / \(total.formatted()) chars")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(.indigo)
                }

                // Gradient progress bar like mockup
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.quaternary)
                            .frame(height: 3)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.39, green: 0.40, blue: 0.95), // #6366F1
                                        Color(red: 0.13, green: 0.83, blue: 0.93), // #22D3EE
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * progress, height: 3)
                            .animation(.linear(duration: 0.15), value: progress)
                    }
                }
                .frame(height: 3)

            default:
                EmptyView()
            }

            Text("Press Esc to cancel")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .frame(width: 340)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(.quaternary, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.3), radius: 16, y: 6)
    }
}
