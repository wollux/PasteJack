import SwiftUI

/// Shows what's new after an update.
struct WhatsNewView: View {

    let onDismiss: () -> Void

    private static let changelog: [(version: String, items: [String])] = [
        ("1.0.0", [
            "Target Keyboard Layout — type into IPMI/iDRAC/RDP with real keycodes (US, DE, UK, FR)",
            "Typing Queue — chain multiple paste items with Tab/Enter separators",
            "Post-Typing Action — auto-send Tab or Enter after typing completes",
            "Snippet Variables — {{date}}, {{hostname}}, {{user}}, {{clipboard}} and more",
            "URL Scheme — trigger PasteJack from Shortcuts, Raycast, or Alfred",
            "Clipboard History — quick-paste from recent clipboard entries in the menu bar",
            "iCloud Sync — sync your snippet library across Macs",
            "Onboarding Wizard — step-by-step permission setup with test button",
            "Check for Updates — easily stay up to date from the menu bar",
        ]),
    ]

    var body: some View {
        VStack(spacing: 0) {
            header
            scrollContent
            footer
        }
        .frame(width: 420, height: 480)
        .background(Color(.windowBackgroundColor))
    }

    private var header: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.26, green: 0.22, blue: 0.79),
                    Color(red: 0.15, green: 0.39, blue: 0.92),
                    Color(red: 0.03, green: 0.57, blue: 0.70),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 8) {
                Text("What's New")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("v\(Constants.appVersion)")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(.white.opacity(0.1)))
            }
        }
        .frame(height: 80)
    }

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(Self.changelog, id: \.version) { entry in
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(entry.items, id: \.self) { item in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "sparkle")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.indigo)
                                    .frame(width: 16, height: 16)

                                Text(item)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.primary.opacity(0.8))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
    }

    private var footer: some View {
        Button {
            UserSettings.shared.lastSeenVersion = Constants.appVersion
            onDismiss()
        } label: {
            Text("Got it")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.indigo)
        .controlSize(.large)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}
