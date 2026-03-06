import SwiftUI

struct SettingsView: View {

    @ObservedObject private var settings = UserSettings.shared
    @ObservedObject private var licenseManager = LicenseManager.shared
    @State private var accessibilityGranted = AccessibilityChecker.hasPermission
    @State private var screenRecordingGranted = ScreenRecordingChecker.hasPermission
    @State private var pollTimer: Timer?
    @State private var licenseKeyInput = ""

    var body: some View {
        VStack(spacing: 0) {
            compactHeader
            gridBody
            Spacer(minLength: 0)
            footer
        }
        .ignoresSafeArea()
        .frame(width: 560, height: 720)
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
        ScrollView {
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

                Spacer().frame(height: 10)

                // License row
                HStack(alignment: .top, spacing: 10) {
                    licenseCard
                    Spacer().frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 8)
        }
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
                        InfoTip(text: "Delay between each keystroke. Lower = faster typing. Increase for slow targets like IPMI consoles.")
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

                CompactRowWithInfo("Countdown", info: "Seconds to wait before typing starts. Gives you time to focus the target window.") {
                    HStack(spacing: 6) {
                        Text("\(settings.countdownSeconds)s")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.indigo)
                        Stepper(
                            "",
                            value: $settings.countdownSeconds,
                            in: Constants.minCountdownSeconds...Constants.maxCountdownSeconds
                        )
                        .labelsHidden()
                        .controlSize(.mini)
                    }
                }

                CompactDivider()

                CompactToggleRowWithInfo("Adaptive Speed", isOn: $settings.adaptiveSpeed, info: "Automatically slows down when the target app can't keep up with keystrokes.")

                CompactDivider()

                // Line delay slider
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Line Delay")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        InfoTip(text: "Extra pause after each newline. Useful for terminals and IPMI consoles that need time to process a line.")
                        Spacer()
                        Text(settings.lineDelayMs == 0 ? "Off" : "\(Int(settings.lineDelayMs))ms")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.indigo)
                    }

                    Slider(
                        value: $settings.lineDelayMs,
                        in: 0...Constants.maxLineDelayMs,
                        step: Constants.lineDelayStepMs
                    )
                    .tint(.indigo)

                    HStack {
                        Text("Off")
                            .font(.system(size: 9))
                            .foregroundStyle(.quaternary)
                        Spacer()
                        Text("2000ms")
                            .font(.system(size: 9))
                            .foregroundStyle(.quaternary)
                    }
                }

                CompactDivider()

                CompactRowWithInfo("Max chars", info: "Safety limit to prevent accidentally typing very long text. Default: 10,000 characters.") {
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
                CompactToggleRowWithInfo("Launch at Login", isOn: $settings.launchAtLogin, info: "Start PasteJack automatically when you log in.")
                CompactDivider()
                CompactToggleRowWithInfo("Play sound", isOn: $settings.playSoundOnComplete, info: "Play a sound when typing is complete.")
                CompactDivider()
                CompactToggleRowWithInfo("Show progress", isOn: $settings.showProgress, info: "Update the menu bar icon to show typing progress.")
                CompactDivider()
                CompactToggleRowWithInfo("Auto-close OCR", isOn: $settings.ocrAutoClose, info: "Automatically close the OCR result window after a few seconds.")
                CompactDivider()
                CompactToggleRowWithInfo("Notifications", isOn: $settings.showNotification, info: "Show a macOS notification when typing completes.")
                CompactDivider()
                CompactToggleRowWithInfo("Sensitive warn", isOn: $settings.sensitiveDetection, info: "Warn before typing if clipboard contains API keys, passwords, or tokens.")
                CompactDivider()
                CompactToggleRowWithInfo("Typing preview", isOn: $settings.showPreview, info: "Show a preview window with text stats before typing starts.")

                CompactDivider()

                CompactRowWithInfo("OCR Language", info: "Preferred language for OCR text recognition. Auto uses system defaults.") {
                    Picker("", selection: $settings.ocrPreferredLanguage) {
                        Text("Auto").tag("")
                        Text("English").tag("en-US")
                        Text("German").tag("de-DE")
                        Text("French").tag("fr-FR")
                        Text("Spanish").tag("es-ES")
                        Text("Italian").tag("it-IT")
                        Text("Portuguese").tag("pt-BR")
                        Text("Chinese").tag("zh-Hans")
                        Text("Japanese").tag("ja-JP")
                        Text("Korean").tag("ko-KR")
                    }
                    .frame(width: 100)
                }

                CompactDivider()

                CompactRowWithInfo("Appearance", info: "Override the system appearance for PasteJack windows.") {
                    Picker("", selection: $settings.appearanceMode) {
                        Text("System").tag("system")
                        Text("Dark").tag("dark")
                        Text("Light").tag("light")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 150)
                }
            }
        }
    }

    // MARK: - Hotkey Card

    private var hotkeyCard: some View {
        CompactCard(icon: "command", label: "Hotkeys") {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Paste as Keystrokes")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    HotkeyRecorderView(
                        keyCode: $settings.pasteHotkeyKeyCode,
                        modifiers: $settings.pasteHotkeyModifiers,
                        defaultKeyCode: Int(Constants.defaultHotkeyKeyCode),
                        defaultModifiers: Int(Constants.defaultHotkeyModifiers)
                    )
                }
                .padding(.vertical, 3)

                CompactDivider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Copy from Screen")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    HotkeyRecorderView(
                        keyCode: $settings.ocrHotkeyKeyCode,
                        modifiers: $settings.ocrHotkeyModifiers,
                        defaultKeyCode: Int(Constants.defaultOCRHotkeyKeyCode),
                        defaultModifiers: Int(Constants.defaultOCRHotkeyModifiers)
                    )
                }
                .padding(.vertical, 3)

                CompactDivider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Type Selected Text")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    HotkeyRecorderView(
                        keyCode: $settings.selectedTextHotkeyKeyCode,
                        modifiers: $settings.selectedTextHotkeyModifiers,
                        defaultKeyCode: Int(Constants.defaultSelectedTextHotkeyKeyCode),
                        defaultModifiers: Int(Constants.defaultSelectedTextHotkeyModifiers)
                    )
                }
                .padding(.vertical, 3)
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

    // MARK: - License Card

    private var licenseCard: some View {
        CompactCard(icon: "heart", label: "License") {
            VStack(spacing: 0) {
                // Status
                HStack(spacing: 7) {
                    Circle()
                        .fill(licenseManager.isLicensed ? .green : .orange)
                        .frame(width: 7, height: 7)
                        .shadow(color: licenseManager.isLicensed ? .green.opacity(0.6) : .orange.opacity(0.6), radius: 3)

                    Text(licenseManager.isLicensed ? "Licensed" : "Free")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(licenseManager.dailyUseCount) / \(Constants.freeUsesPerDay) free uses today")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 3)

                CompactDivider()

                if licenseManager.isLicensed {
                    // Show masked key + remove button
                    HStack {
                        Text(maskedKey(settings.licenseKey))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Remove") {
                            licenseManager.removeLicense()
                            licenseKeyInput = ""
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(.vertical, 3)
                } else {
                    // Key input + activate
                    HStack(spacing: 8) {
                        TextField("License key", text: $licenseKeyInput)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 11, design: .monospaced))

                        Button {
                            Task {
                                _ = await licenseManager.validateLicense(key: licenseKeyInput)
                            }
                        } label: {
                            if licenseManager.validationInProgress {
                                ProgressView()
                                    .controlSize(.mini)
                                    .frame(width: 50)
                            } else {
                                Text("Activate")
                                    .frame(width: 50)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.indigo)
                        .controlSize(.small)
                        .disabled(licenseKeyInput.isEmpty || licenseManager.validationInProgress)
                    }
                    .padding(.vertical, 3)

                    if let error = licenseManager.validationError {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(.orange)
                            Text(error)
                                .font(.system(size: 10))
                                .foregroundStyle(.orange)
                        }
                        .padding(.top, 2)
                    }

                    CompactDivider()

                    Button {
                        if let url = URL(string: Constants.lemonSqueezyCheckoutURL) {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        Label("Buy License \u{2014} \(Constants.licensePrice)", systemImage: "heart.fill")
                            .font(.system(size: 11, design: .monospaced))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.pink)
                    .controlSize(.small)
                    .padding(.top, 4)
                }
            }
        }
    }

    private func maskedKey(_ key: String) -> String {
        guard key.count > 8 else { return String(repeating: "*", count: key.count) }
        let prefix = key.prefix(4)
        let suffix = key.suffix(4)
        return "\(prefix)...\(suffix)"
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 6) {
            HStack(spacing: 16) {
                footerStat(icon: "keyboard", label: "Pastes", value: settings.totalPasteCount)
                footerStat(icon: "doc.text.viewfinder", label: "OCRs", value: settings.totalOCRCount)
                footerStat(icon: "character.cursor.ibeam", label: "Chars", value: settings.totalCharsTyped)
            }
            Text("Made by Wolfgang Vieregg")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.quaternary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }

    private func footerStat(icon: String, label: String, value: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
            Text("\(value.formatted()) \(label)")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.tertiary)
        }
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

private struct CompactRowWithInfo<Content: View>: View {
    let label: String
    let info: String
    @ViewBuilder let trailing: Content

    init(_ label: String, info: String, @ViewBuilder trailing: () -> Content) {
        self.label = label
        self.info = info
        self.trailing = trailing()
    }

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            InfoTip(text: info)
            Spacer()
            trailing
        }
        .padding(.vertical, 5)
    }
}

private struct CompactToggleRowWithInfo: View {
    let label: String
    @Binding var isOn: Bool
    let info: String

    init(_ label: String, isOn: Binding<Bool>, info: String) {
        self.label = label
        self._isOn = isOn
        self.info = info
    }

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            InfoTip(text: info)
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .tint(.indigo)
                .controlSize(.mini)
                .labelsHidden()
        }
        .padding(.vertical, 3)
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

private struct InfoTip: View {
    let text: String
    @State private var isShowing = false

    var body: some View {
        Button {
            isShowing.toggle()
        } label: {
            Image(systemName: "info.circle")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isShowing, arrowEdge: .trailing) {
            Text(text)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .padding(10)
                .frame(maxWidth: 220)
                .fixedSize(horizontal: false, vertical: true)
        }
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
