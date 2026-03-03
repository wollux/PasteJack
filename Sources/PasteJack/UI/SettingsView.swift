import SwiftUI

struct SettingsView: View {

    @ObservedObject private var settings = UserSettings.shared
    @State private var accessibilityGranted = AccessibilityChecker.hasPermission
    @State private var screenRecordingGranted = ScreenRecordingChecker.hasPermission
    @State private var pollTimer: Timer?

    var body: some View {
        VStack(spacing: 0) {
            gradientHeader

            ScrollView {
                VStack(spacing: 14) {
                    typingCard
                    behaviorCard
                    hotkeyCard
                    ocrCard
                    accessibilityCard
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 8)
            }

            footer
        }
        .frame(width: 480, height: 660)
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

            VStack(spacing: 8) {
                Image(systemName: "gearshape")
                    .font(.system(size: 36, weight: .thin))
                    .foregroundStyle(.white.opacity(0.9))

                Text("PasteJack Settings")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(.vertical, 20)
        }
        .frame(height: 120)
        .clipShape(UnevenRoundedRectangle(
            topLeadingRadius: 0,
            bottomLeadingRadius: 20,
            bottomTrailingRadius: 20,
            topTrailingRadius: 0
        ))
    }

    // MARK: - Typing Card

    private var typingCard: some View {
        SettingsCard(icon: "keyboard", iconColor: .blue, title: "Typing") {
            VStack(spacing: 12) {
                HStack {
                    Text("Speed")
                        .frame(width: 70, alignment: .leading)
                    Slider(
                        value: $settings.keystrokeDelayMs,
                        in: Constants.minDelayMs...Constants.maxDelayMs,
                        step: Constants.delayStepMs
                    )
                    Text("\(Int(settings.keystrokeDelayMs))ms")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .frame(width: 48, alignment: .trailing)
                }

                Divider()

                HStack {
                    Text("Countdown")
                        .frame(width: 90, alignment: .leading)
                    Spacer()
                    Stepper(
                        "\(settings.countdownSeconds)s",
                        value: $settings.countdownSeconds,
                        in: Constants.minCountdownSeconds...Constants.maxCountdownSeconds
                    )
                    .labelsHidden()
                    Text("\(settings.countdownSeconds)s")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .frame(width: 30, alignment: .trailing)
                }

                Divider()

                HStack {
                    Text("Max characters")
                        .frame(width: 110, alignment: .leading)
                    Spacer()
                    TextField("", value: $settings.maxCharacters, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 90)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
    }

    // MARK: - Behavior Card

    private var behaviorCard: some View {
        SettingsCard(icon: "slider.horizontal.3", iconColor: .purple, title: "Behavior") {
            VStack(spacing: 10) {
                Toggle("Launch at Login", isOn: $settings.launchAtLogin)
                Divider()
                Toggle("Play sound on completion", isOn: $settings.playSoundOnComplete)
                Divider()
                Toggle("Show progress in menu bar", isOn: $settings.showProgress)
            }
        }
    }

    // MARK: - Hotkey Card

    private var hotkeyCard: some View {
        SettingsCard(icon: "command", iconColor: .orange, title: "Hotkeys") {
            VStack(spacing: 10) {
                HStack {
                    Text("Paste as Keystrokes")
                        .foregroundStyle(.secondary)
                    Spacer()
                    HotkeyBadge(keys: ["⌃", "⇧", "V"])
                }
                Divider()
                HStack {
                    Text("Copy from Screen")
                        .foregroundStyle(.secondary)
                    Spacer()
                    HotkeyBadge(keys: ["⌃", "⇧", "C"])
                }
            }
        }
    }

    // MARK: - OCR Card

    private var ocrCard: some View {
        SettingsCard(icon: "doc.text.viewfinder", iconColor: .teal, title: "Screen OCR") {
            VStack(spacing: 10) {
                // Screen Recording permission
                HStack {
                    Circle()
                        .fill(screenRecordingGranted ? .green : .orange)
                        .frame(width: 8, height: 8)
                    Text(screenRecordingGranted ? "Screen Recording granted" : "Screen Recording required")
                        .foregroundStyle(screenRecordingGranted ? .green : .orange)
                        .font(.callout.weight(.medium))
                    Spacer()
                    if !screenRecordingGranted {
                        Button("Grant Access") {
                            ScreenRecordingChecker.requestPermission()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }

                Divider()

                Toggle("Auto-close result window", isOn: $settings.ocrAutoClose)

                if settings.ocrAutoClose {
                    HStack {
                        Text("Close after")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Stepper(
                            "\(settings.ocrAutoCloseSeconds)s",
                            value: $settings.ocrAutoCloseSeconds,
                            in: Constants.minOCRAutoCloseSeconds...Constants.maxOCRAutoCloseSeconds
                        )
                        .labelsHidden()
                        Text("\(settings.ocrAutoCloseSeconds)s")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .frame(width: 30, alignment: .trailing)
                    }
                }
            }
        }
    }

    // MARK: - Accessibility Card

    private var allPermissionsGranted: Bool {
        accessibilityGranted && screenRecordingGranted
    }

    private var accessibilityCard: some View {
        SettingsCard(
            icon: allPermissionsGranted ? "lock.open.fill" : "lock.fill",
            iconColor: allPermissionsGranted ? .green : .orange,
            title: "Permissions"
        ) {
            VStack(spacing: 10) {
                HStack {
                    Circle()
                        .fill(accessibilityGranted ? .green : .orange)
                        .frame(width: 8, height: 8)
                    Text(accessibilityGranted ? "Accessibility granted" : "Accessibility required")
                        .foregroundStyle(accessibilityGranted ? .green : .orange)
                        .font(.callout.weight(.medium))
                    Spacer()
                    if !accessibilityGranted {
                        Button("Grant Access") {
                            AccessibilityChecker.requestPermission()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }

                if !allPermissionsGranted {
                    Divider()

                    Button {
                        NotificationCenter.default.post(name: .showOnboarding, object: nil)
                    } label: {
                        Label("Setup Permissions", systemImage: "lock.shield")
                            .frame(maxWidth: .infinity)
                    }
                    .controlSize(.small)
                }
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 2) {
            Text("PasteJack v0.1.0")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Text("Made by Wolfgang Vieregg")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 12)
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

// MARK: - Components

private struct SettingsCard<Content: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text(title)
                    .font(.headline)
            } icon: {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .font(.body)
            }

            content
                .padding(.leading, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }
}

private struct HotkeyBadge: View {
    let keys: [String]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(keys, id: \.self) { key in
                Text(key)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .frame(minWidth: 26, minHeight: 26)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.quaternary)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(.tertiary, lineWidth: 0.5)
                    )
            }
        }
    }
}
