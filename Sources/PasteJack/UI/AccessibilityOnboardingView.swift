import SwiftUI

struct AccessibilityOnboardingView: View {

    @State private var accessibilityGranted = AccessibilityChecker.hasPermission
    @State private var screenRecordingGranted = ScreenRecordingChecker.hasPermission
    @State private var pollTimer: Timer?
    @State private var pulseAnimation = false
    @State private var autoDismissScheduled = false
    var onDismiss: (() -> Void)?

    private var allGranted: Bool {
        accessibilityGranted && screenRecordingGranted
    }

    private var grantedCount: Int {
        (accessibilityGranted ? 1 : 0) + (screenRecordingGranted ? 1 : 0)
    }

    var body: some View {
        VStack(spacing: 0) {
            gradientHeader

            ScrollView {
                VStack(spacing: 14) {
                    permissionsCard
                    privacyCard
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 8)
            }

            Spacer(minLength: 12)
            footerSection
        }
        .frame(width: 480, height: 580)
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

    // MARK: - Permissions Card

    private var permissionsCard: some View {
        OnboardingCard(
            icon: "lock.shield.fill",
            iconColor: .blue,
            title: "Required Permissions"
        ) {
            VStack(spacing: 14) {
                permissionRow(
                    icon: "keyboard",
                    title: "Accessibility",
                    description: "Simulates keystrokes to paste into apps that block clipboard access.",
                    granted: accessibilityGranted,
                    action: { AccessibilityChecker.requestPermission() }
                )

                Divider()

                permissionRow(
                    icon: "rectangle.dashed.badge.record",
                    title: "Screen Recording",
                    description: "Captures screen regions for OCR text recognition.",
                    granted: screenRecordingGranted,
                    action: { ScreenRecordingChecker.requestPermission() }
                )
            }
        }
    }

    private func permissionRow(
        icon: String,
        title: String,
        description: String,
        granted: Bool,
        action: @escaping () -> Void
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(granted ? .green : .orange)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.callout.weight(.semibold))
                    Spacer()
                    if granted {
                        Label("Granted", systemImage: "checkmark.circle.fill")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.green)
                    } else {
                        Button("Grant Access") { action() }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                    }
                }
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Privacy Card

    private var privacyCard: some View {
        OnboardingCard(
            icon: "eye.slash.fill",
            iconColor: .green,
            title: "Your Privacy"
        ) {
            PrivacyBullet(text: "No keylogging \u{2014} only sends outgoing keystrokes")
            PrivacyBullet(text: "No network \u{2014} runs 100% offline on your Mac")
            PrivacyBullet(text: "No background activity \u{2014} only runs when you trigger it")
        }
    }

    // MARK: - Footer

    private func dismiss() {
        UserSettings.shared.hasSeenOnboarding = true
        onDismiss?()
    }

    private var footerSection: some View {
        VStack(spacing: 12) {
            if allGranted {
                Button {
                    dismiss()
                } label: {
                    Label("Get Started", systemImage: "arrow.right.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .controlSize(.large)
            } else {
                Button {
                    if !accessibilityGranted {
                        AccessibilityChecker.requestPermission()
                    }
                    if !screenRecordingGranted {
                        ScreenRecordingChecker.requestPermission()
                    }
                } label: {
                    Label("Grant All Permissions", systemImage: "lock.open")
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
                .fill(allGranted ? .green : .orange)
                .frame(width: 8, height: 8)
                .scaleEffect(pulseAnimation && !allGranted ? 1.4 : 1.0)
                .opacity(pulseAnimation && !allGranted ? 0.5 : 1.0)
                .animation(
                    allGranted
                        ? .default
                        : .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                    value: pulseAnimation
                )

            Text(allGranted
                 ? "All permissions granted"
                 : "\(grantedCount) of 2 permissions granted")
                .font(.caption)
                .foregroundStyle(allGranted ? .green : .secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(allGranted
                      ? Color.green.opacity(0.1)
                      : Color.secondary.opacity(0.08))
        )
        .onAppear { pulseAnimation = true }
    }

    // MARK: - Polling

    private func startPolling() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                let accGranted = AccessibilityChecker.hasPermission
                let scrGranted = ScreenRecordingChecker.hasPermission
                if accGranted != accessibilityGranted || scrGranted != screenRecordingGranted {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        accessibilityGranted = accGranted
                        screenRecordingGranted = scrGranted
                    }
                }

                // Auto-dismiss when all permissions are granted
                if accGranted && scrGranted && !autoDismissScheduled {
                    autoDismissScheduled = true
                    try? await Task.sleep(for: .seconds(1.5))
                    dismiss()
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
