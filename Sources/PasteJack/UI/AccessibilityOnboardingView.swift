import SwiftUI

struct AccessibilityOnboardingView: View {

    @State private var accessibilityGranted = AccessibilityChecker.hasPermission
    @State private var screenRecordingGranted = ScreenRecordingChecker.hasPermission
    @State private var pollTimer: Timer?
    @State private var pulseAnimation = false
    @State private var floatAnimation = false
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
            compactHeader
            bodyContent
            Spacer(minLength: 0)
            footerSection
        }
        .frame(width: 520, height: 480)
        .background(Color(.windowBackgroundColor))
        .onAppear { startPolling() }
        .onDisappear { stopPolling() }
    }

    // MARK: - Compact Header

    private var compactHeader: some View {
        ZStack(alignment: .leading) {
            LinearGradient(
                colors: [
                    Color(red: 0.26, green: 0.22, blue: 0.79),
                    Color(red: 0.15, green: 0.39, blue: 0.92),
                    Color(red: 0.03, green: 0.57, blue: 0.70),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack {
                LinearGradient(
                    colors: [.white.opacity(0.07), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 30)
                Spacer()
            }

            HStack(spacing: 14) {
                Image(systemName: "keyboard")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.3), radius: 8, y: 2)
                    .offset(y: floatAnimation ? -4 : 0)
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: floatAnimation
                    )
                    .onAppear { floatAnimation = true }

                VStack(alignment: .leading, spacing: 2) {
                    Text("PasteJack")
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Keystroke Simulation for macOS")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.55))
                }

                Spacer()

                // Counter badge
                VStack(spacing: 2) {
                    Text("\(grantedCount)/2")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(allGranted ? .green : .yellow)

                    Text("GRANTED")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                        .tracking(0.8)
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 60)
    }

    // MARK: - Body

    private var bodyContent: some View {
        VStack(spacing: 8) {
            // Permission cards side by side
            HStack(alignment: .top, spacing: 8) {
                PermissionCard(
                    icon: "keyboard",
                    title: "Accessibility",
                    description: "Simulates keystrokes via CGEvent to bypass paste-blocking.",
                    granted: accessibilityGranted,
                    onGrant: { AccessibilityChecker.requestPermission() }
                )

                PermissionCard(
                    icon: "rectangle.dashed.badge.record",
                    title: "Screen Recording",
                    description: "Captures screen regions for on-device OCR recognition.",
                    granted: screenRecordingGranted,
                    onGrant: { ScreenRecordingChecker.requestPermission() }
                )
            }

            // Privacy pills
            privacyPills
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
    }

    // MARK: - Privacy Pills

    private var privacyPills: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "eye.slash")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                Text("YOUR PRIVACY")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .tracking(1.2)
            }
            .padding(.bottom, 9)

            HStack(spacing: 7) {
                PrivacyPill(text: "No keylogging")
                PrivacyPill(text: "No network calls")
                PrivacyPill(text: "No background activity")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(.quaternary, lineWidth: 0.5)
        )
    }

    // MARK: - Footer

    private func dismiss() {
        UserSettings.shared.hasSeenOnboarding = true
        onDismiss?()
    }

    private var footerSection: some View {
        VStack(spacing: 8) {
            if allGranted {
                Button {
                    dismiss()
                } label: {
                    Label("Get Started", systemImage: "checkmark.circle.fill")
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
                .tint(.indigo)
                .controlSize(.large)
            }

            statusPill
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 13)
    }

    private var statusPill: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(allGranted ? .green : .yellow)
                .frame(width: 6, height: 6)
                .shadow(color: allGranted ? .green.opacity(0.6) : .yellow.opacity(0.6), radius: 4)
                .scaleEffect(pulseAnimation && !allGranted ? 1.4 : 1.0)
                .opacity(pulseAnimation && !allGranted ? 0.5 : 1.0)
                .animation(
                    allGranted
                        ? .default
                        : .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                    value: pulseAnimation
                )

            Text(allGranted
                 ? "All permissions granted \u{2014} ready to go"
                 : "\(grantedCount) of 2 permissions granted")
                .font(.system(size: 11))
                .foregroundStyle(allGranted ? .green : .secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(allGranted
                      ? Color.green.opacity(0.08)
                      : Color.secondary.opacity(0.06))
                .overlay(
                    Capsule()
                        .strokeBorder(.quaternary, lineWidth: 0.5)
                )
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

// MARK: - Permission Card

private struct PermissionCard: View {
    let icon: String
    let title: String
    let description: String
    let granted: Bool
    let onGrant: () -> Void

    private var iconFillColor: Color {
        granted ? Color.green.opacity(0.12) : Color.primary.opacity(0.06)
    }

    private var iconBorderColor: Color {
        granted ? Color.green.opacity(0.3) : Color.primary.opacity(0.1)
    }

    private var cardFillColor: Color {
        granted ? Color.green.opacity(0.04) : Color(.windowBackgroundColor)
    }

    private var cardBorderColor: Color {
        granted ? Color.green.opacity(0.2) : Color.secondary.opacity(0.2)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            iconAndText
            Spacer().frame(height: 10)
            statusOrButton
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(cardFillColor))
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(cardBorderColor, lineWidth: 0.5)
        )
        .animation(.easeInOut(duration: 0.3), value: granted)
    }

    private var iconAndText: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(granted ? .green : .secondary)
                    .frame(width: 38, height: 38)
                    .background(RoundedRectangle(cornerRadius: 9).fill(iconFillColor))
                    .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(iconBorderColor, lineWidth: 1))

                if granted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.green)
                        .background(Circle().fill(Color(.windowBackgroundColor)).padding(1))
                        .offset(x: 4, y: 4)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                Text(description)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
            }
        }
    }

    @ViewBuilder
    private var statusOrButton: some View {
        HStack {
            Spacer()
            if granted {
                grantedBadge
            } else {
                Button("Grant Access") { onGrant() }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                    .controlSize(.small)
            }
            Spacer()
        }
    }

    private var grantedBadge: some View {
        HStack(spacing: 5) {
            Circle().fill(.green).frame(width: 6, height: 6)
            Text("Granted")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.green)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(Color.green.opacity(0.1))
        )
        .overlay(
            Capsule().strokeBorder(Color.green.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Privacy Pill

private struct PrivacyPill: View {
    let text: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "checkmark")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.green)

            Text(text)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(Color.green.opacity(0.06))
                .overlay(
                    Capsule()
                        .strokeBorder(Color.green.opacity(0.12), lineWidth: 0.5)
                )
        )
    }
}
