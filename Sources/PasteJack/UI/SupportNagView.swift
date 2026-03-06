import SwiftUI

struct SupportNagView: View {

    @ObservedObject private var licenseManager = LicenseManager.shared
    @State private var licenseKeyInput = ""
    var onDismiss: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            nagHeader
            nagBody
            Spacer(minLength: 8)
            nagFooter
        }
        .ignoresSafeArea()
        .frame(width: 520)
        .background(Color(.windowBackgroundColor))
    }

    // MARK: - Header

    private var nagHeader: some View {
        ZStack(alignment: .leading) {
            LinearGradient(
                colors: [
                    Color(red: 0.76, green: 0.22, blue: 0.42),
                    Color(red: 0.85, green: 0.35, blue: 0.25),
                    Color(red: 0.95, green: 0.55, blue: 0.20),
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
                Image(systemName: "heart.fill")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.3), radius: 8, y: 2)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Support PasteJack")
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Keep the project alive")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.55))
                }

                Spacer()

                // Usage badge
                VStack(spacing: 2) {
                    Text("\(licenseManager.dailyUseCount)/\(Constants.freeUsesPerDay)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.yellow)

                    Text("TODAY")
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

    private var nagBody: some View {
        VStack(spacing: 10) {
            // Message card
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                    Text("WHY SUPPORT?")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .tracking(1.2)
                }
                .padding(.bottom, 9)

                Text("PasteJack is free and always will be. No features are locked. A \(Constants.licensePrice) license removes this reminder and supports continued development.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(.quaternary, lineWidth: 0.5)
            )

            // License activation card
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    Image(systemName: "key")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                    Text("ACTIVATE LICENSE")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .tracking(1.2)
                }
                .padding(.bottom, 9)

                HStack(spacing: 8) {
                    TextField("License key", text: $licenseKeyInput)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))

                    Button {
                        Task {
                            _ = await licenseManager.validateLicense(key: licenseKeyInput)
                            if licenseManager.isLicensed {
                                onDismiss?()
                            }
                        }
                    } label: {
                        if licenseManager.validationInProgress {
                            ProgressView()
                                .controlSize(.small)
                                .frame(width: 60)
                        } else {
                            Text("Activate")
                                .frame(width: 60)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                    .controlSize(.small)
                    .disabled(licenseKeyInput.isEmpty || licenseManager.validationInProgress)
                }

                if let error = licenseManager.validationError {
                    HStack(spacing: 5) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.orange)
                        Text(error)
                            .font(.system(size: 11))
                            .foregroundStyle(.orange)
                    }
                    .padding(.top, 6)
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
        .padding(.horizontal, 14)
        .padding(.top, 12)
    }

    // MARK: - Footer

    private var nagFooter: some View {
        VStack(spacing: 8) {
            Button {
                if let url = URL(string: Constants.lemonSqueezyCheckoutURL) {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                Label("Buy License \u{2014} \(Constants.licensePrice)", systemImage: "heart.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.pink)
            .controlSize(.large)

            Button {
                onDismiss?()
            } label: {
                Text("Continue Free")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 13)
    }
}
