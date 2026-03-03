import SwiftUI

struct AccessibilityOnboardingView: View {

    @State private var permissionGranted = AccessibilityChecker.hasPermission
    @State private var pollTimer: Timer?
    @State private var pulseAnimation = false
    var onDismiss: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            gradientHeader
            cardSection
            Spacer(minLength: 12)
            footerSection
        }
        .frame(width: 480, height: 520)
        .background(Color(.windowBackgroundColor))
        .onAppear { startPolling() }
        .onDisappear { stopPolling() }
    }

    // MARK: - Gradient Header

    private var gradientHeader: some View {
        ZStack {
            LinearGradient(
                colors: [.indigo, .blue, .cyan],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 14) {
                Image(systemName: "keyboard")
                    .font(.system(size: 56, weight: .thin))
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.2), radius: 8, y: 4)

                Text("PasteJack")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Keystroke Simulation for macOS")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.75))
            }
            .padding(.vertical, 32)
        }
        .frame(height: 200)
        .clipShape(UnevenRoundedRectangle(
            topLeadingRadius: 0,
            bottomLeadingRadius: 20,
            bottomTrailingRadius: 20,
            topTrailingRadius: 0
        ))
    }

    // MARK: - Cards

    private var cardSection: some View {
        VStack(spacing: 14) {
            // Card 1: Why
            OnboardingCard(
                icon: "lock.shield.fill",
                iconColor: .blue,
                title: "Why this permission?"
            ) {
                Text("PasteJack uses the macOS Accessibility API to simulate keystrokes — this lets you \"type\" clipboard contents into apps that block pasting.")
                Text("macOS requires your explicit approval for this. It's a one-time security measure by Apple.")
            }

            // Card 2: Privacy
            OnboardingCard(
                icon: "eye.slash.fill",
                iconColor: .green,
                title: "Your Privacy"
            ) {
                PrivacyBullet(text: "No keylogging — only sends outgoing keystrokes")
                PrivacyBullet(text: "No network — runs 100% offline on your Mac")
                PrivacyBullet(text: "No background activity — only runs when you trigger it")
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 12) {
            if permissionGranted {
                Button {
                    onDismiss?()
                } label: {
                    Label("Get Started", systemImage: "arrow.right.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .controlSize(.large)
            } else {
                Button {
                    AccessibilityChecker.requestPermission()
                } label: {
                    Label("Open System Settings", systemImage: "gear")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

            statusPill
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }

    private var statusPill: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(permissionGranted ? .green : .orange)
                .frame(width: 8, height: 8)
                .scaleEffect(pulseAnimation && !permissionGranted ? 1.4 : 1.0)
                .opacity(pulseAnimation && !permissionGranted ? 0.5 : 1.0)
                .animation(
                    permissionGranted
                        ? .default
                        : .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                    value: pulseAnimation
                )

            Text(permissionGranted ? "Permission granted" : "Waiting for permission...")
                .font(.caption)
                .foregroundStyle(permissionGranted ? .green : .secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(permissionGranted
                      ? Color.green.opacity(0.1)
                      : Color.secondary.opacity(0.08))
        )
        .onAppear { pulseAnimation = true }
    }

    // MARK: - Polling

    private func startPolling() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                let granted = AccessibilityChecker.hasPermission
                if granted != permissionGranted {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        permissionGranted = granted
                    }
                }
            }
        }
    }

    private func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }
}

// MARK: - Components

private struct OnboardingCard<Content: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label {
                Text(title)
                    .font(.headline)
            } icon: {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .font(.body)
            }

            VStack(alignment: .leading, spacing: 5) {
                content
            }
            .font(.callout)
            .foregroundStyle(.secondary)
            .padding(.leading, 28)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }
}

private struct PrivacyBullet: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark")
                .font(.caption.bold())
                .foregroundStyle(.green)
                .frame(width: 14, height: 14)
            Text(text)
        }
    }
}
