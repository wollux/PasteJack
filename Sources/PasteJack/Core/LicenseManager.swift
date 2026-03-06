import Foundation

@MainActor
final class LicenseManager: ObservableObject {

    static let shared = LicenseManager()

    @Published var validationInProgress = false
    @Published var validationError: String?

    private let settings = UserSettings.shared

    var isLicensed: Bool {
        !settings.licenseKey.isEmpty && settings.licenseValid
    }

    // MARK: - Daily Usage Counter

    func recordUsage() {
        let today = Self.todayString()
        if settings.dailyUseDate != today {
            settings.dailyUseDate = today
            settings.dailyUseCount = 1
        } else {
            settings.dailyUseCount += 1
        }
    }

    func shouldShowNag() -> Bool {
        settings.dailyUseCount > Constants.freeUsesPerDay && !isLicensed
    }

    var dailyUseCount: Int {
        let today = Self.todayString()
        if settings.dailyUseDate != today {
            return 0
        }
        return settings.dailyUseCount
    }

    // MARK: - License Validation

    func validateLicense(key: String) async -> Bool {
        validationInProgress = true
        validationError = nil

        defer { validationInProgress = false }

        guard let url = URL(string: Constants.lemonSqueezyValidateURL) else {
            validationError = "Invalid validation URL"
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let body = "license_key=\(key)"
        request.httpBody = body.data(using: .utf8)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                validationError = "Invalid response"
                return false
            }

            if httpResponse.statusCode == 200 {
                // Parse response to check validity
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let valid = json["valid"] as? Bool, valid {
                    settings.licenseKey = key
                    settings.licenseValid = true
                    return true
                } else {
                    validationError = "Invalid license key"
                    return false
                }
            } else {
                validationError = "Validation failed (HTTP \(httpResponse.statusCode))"
                return false
            }
        } catch {
            validationError = "Network error: \(error.localizedDescription)"
            return false
        }
    }

    func removeLicense() {
        settings.licenseKey = ""
        settings.licenseValid = false
        validationError = nil
    }

    // MARK: - Helpers

    private static func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
