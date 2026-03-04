import SwiftUI

struct SettingsView: View {

    @ObservedObject private var settings = UserSettings.shared
    @State private var accessibilityGranted = AccessibilityChecker.hasPermission
    @State private var screenRecordingGranted = ScreenRecordingChecker.hasPermission
    @State private var pollTimer: Timer?

    var body: some View {
        VStack(spacing: 0) {
            compactHeader
            gridBody
            Spacer(minLength: 0)
            footer
        }
        .ignoresSafeArea()
        .frame(width: 560)
        .background(Color(.windowBackgroundColor))
        .onAppear { startPolling() }
        .onDisappear { stopPolling() }
    }

    // MARK: - Compact Header

    private var compactHeader: some View {
        ZStack(alignment: .leading) {
            LinearGradient(
                colors: [
                    Color(red: 0.26, green: 0.22, blue: 0.79),  // #4338CA
                    Color(red: 0.15, green: 0.39, blue: 0.92),  // #2563EB
                    Color(red: 0.03, green: 0.57, blue: 0.70),  // #0891B2
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Subtle glare overlay
            VStack {
                LinearGradient(
                    colors: [.white.opacity(0.07), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 30)
                Spacer()
            }

            HStack(spacing: 12) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.3), radius: 6, y: 2)

                VStack(alignment: .leading, spacing: 2) {
                    Text("PasteJack Settings")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("v\(Constants.appVersion)")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 56)
    }

    // MARK: - 2-Column Grid Body

    private var gridBody: some View {
        VStack(spacing: 0) {
            // Top row: Typing + Behavior
            HStack(alignment: .top, spacing: 10) {
                typingCard
                behaviorCard
            }

            Spacer().frame(height: 10)

            // Bottom row: Hotkeys + Permissions
            HStack(alignment: .top, spacing: 10) {
                hotkeyCard
                permissionsCard
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
    }

    // MARK: - Typing Card

    private var typingCard: some View {
        CompactCard(icon: "keyboard", label: "Typing") {
            VStack(spacing: 0) {
                // Speed slider
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Speed")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(settings.keystrokeDelayMs))ms")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.indigo)
                    }

                    Slider(
                        value: $settings.keystrokeDelayMs,
                        in: Constants.minDelayMs...Constants.maxDelayMs,
                        step: Constants.delayStepMs
                    )
                    .tint(.indigo)

                    HStack {
                        Text("5ms fast")
                            .font(.system(size: 9))
                            .foregroundStyle(.quaternary)
                        Spacer()
                        Text("200ms slow")
                            .font(.system(size: 9))
                            .foregroundStyle(.quaternary)
                    }
                }

                CompactDivider()

                CompactRow("Countdown") {
                    Stepper(
                        "\(settings.countdownSeconds)s",
                        value: $settings.countdownSeconds,
                        in: Constants.minCountdownSeconds...Constants.maxCountdownSeconds
                    )
                    .labelsHidden()
                    .controlSize(.mini)
                }

                CompactDivider()

                CompactRow("Max chars") {
                    Text("\(settings.maxCharacters.formatted())")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.primary.opacity(0.8))
                }
            }
        }
    }

    // MARK: - Behavior Card

    private var behaviorCard: some View {
        CompactCard(icon: "bolt", label: "Behavior") {
            VStack(spacing: 0) {
                CompactToggleRow("Launch at Login", isOn: $settings.launchAtLogin)
                CompactDivider()
                CompactToggleRow("Play sound", isOn: $settings.playSoundOnComplete)
                CompactDivider()
                CompactToggleRow("Show progress", isOn: $settings.showProgress)
                CompactDivider()
                CompactToggleRow("Auto-close OCR", isOn: $settings.ocrAutoClose)
            }
        }
    }

    // MARK: - Hotkey Card

    private var hotkeyCard: some View {
        CompactCard(icon: "command", label: "Hotkeys") {
            VStack(spacing: 0) {
                CompactRow("Paste as Keystrokes") {
                    HotkeyBadge(keys: ["⌃", "⇧", "V"])
                }
                CompactDivider()
                CompactRow("Copy from Screen") {
                    HotkeyBadge(keys: ["⌃", "⇧", "C"])
                }
            }
        }
    }

    // MARK: - Permissions Card

    private var allPermissionsGranted: Bool {
        accessibilityGranted && screenRecordingGranted
    }

    private var permissionsCard: some View {
        CompactCard(icon: "lock.shield", label: "Permissions") {
            VStack(spacing: 0) {
                permissionDotRow(
                    label: "Accessibility",
                    granted: accessibilityGranted
                )
                CompactDivider()
                permissionDotRow(
                    label: "Screen Recording",
                    granted: screenRecordingGranted
                )
                CompactDivider()

                Button {
                    NotificationCenter.default.post(name: .showOnboarding, object: nil)
                } label: {
                    Label("Setup Permissions", systemImage: "lock.shield")
                        .font(.system(size: 11, design: .monospaced))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.indigo)
                .controlSize(.small)
                .padding(.top, 6)
            }
        }
    }

    private func permissionDotRow(label: String, granted: Bool) -> some View {
        HStack(spacing: 7) {
            Circle()
                .fill(granted ? .green : .orange)
                .frame(width: 7, height: 7)
                .shadow(color: granted ? .green.opacity(0.6) : .orange.opacity(0.6), radius: 3)

            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            Spacer()

            Text(granted ? "Granted" : "Required")
                .font(.system(size: 10))
                .foregroundStyle(granted ? .green : .orange)
        }
        .padding(.vertical, 3)
    }

    // MARK: - Footer

    private var footer: some View {
        Text("Made by Wolfgang Vieregg")
            .font(.system(size: 10, design: .monospaced))
            .foregroundStyle(.quaternary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
    }

    // MARK: - Polling

    private func startPolling() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            Task { @MainActor in
                let accGranted = AccessibilityChecker.hasPermission
                let scrGranted = ScreenRecordingChecker.hasPermission
                if accGranted != accessibilityGranted || scrGranted != screenRecordingGranted {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        accessibilityGranted = accGranted
                        screenRecordingGranted = scrGranted
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

// MARK: - Compact Card Components

private struct CompactCard<Content: View>: View {
    let icon: String
    let label: String
    @ViewBuilder let content: Content

    init(icon: String, label: String, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.label = label
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section label
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)

                Text(label.uppercased())
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .tracking(1.2)
            }
            .padding(.bottom, 10)

            content
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
}

private struct CompactRow<Content: View>: View {
    let label: String
    @ViewBuilder let trailing: Content

    init(_ label: String, @ViewBuilder trailing: () -> Content) {
        self.label = label
        self.trailing = trailing()
    }

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Spacer()
            trailing
        }
        .padding(.vertical, 5)
    }
}

private struct CompactToggleRow: View {
    let label: String
    @Binding var isOn: Bool

    init(_ label: String, isOn: Binding<Bool>) {
        self.label = label
        self._isOn = isOn
    }

    var body: some View {
        Toggle(label, isOn: $isOn)
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
            .toggleStyle(.switch)
            .tint(.indigo)
            .controlSize(.mini)
            .padding(.vertical, 3)
    }
}

private struct CompactDivider: View {
    var body: some View {
        Divider()
            .padding(.vertical, 2)
    }
}

private struct HotkeyBadge: View {
    let keys: [String]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(keys, id: \.self) { key in
                Text(key)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .frame(minWidth: 22, minHeight: 22)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.quaternary.opacity(0.5))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(.tertiary, lineWidth: 0.5)
                    )
            }
        }
    }
}
