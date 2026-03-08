import AppKit
import Foundation

/// Resolves template variables in snippet text before typing.
enum SnippetVariableResolver {

    static let variables: [(token: String, desc: String)] = [
        ("{{date}}", "yyyy-MM-dd"),
        ("{{time}}", "HH:mm:ss"),
        ("{{datetime}}", "yyyy-MM-dd HH:mm:ss"),
        ("{{timestamp}}", "Unix timestamp"),
        ("{{hostname}}", "Computer name"),
        ("{{user}}", "Username"),
        ("{{clipboard}}", "Current clipboard"),
        ("{{uuid}}", "Random UUID"),
    ]

    static func resolve(_ text: String) -> String {
        var result = text

        let dateFormatter = DateFormatter()
        let now = Date()

        if result.contains("{{date}}") {
            dateFormatter.dateFormat = "yyyy-MM-dd"
            result = result.replacingOccurrences(of: "{{date}}", with: dateFormatter.string(from: now))
        }

        if result.contains("{{time}}") {
            dateFormatter.dateFormat = "HH:mm:ss"
            result = result.replacingOccurrences(of: "{{time}}", with: dateFormatter.string(from: now))
        }

        if result.contains("{{datetime}}") {
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            result = result.replacingOccurrences(of: "{{datetime}}", with: dateFormatter.string(from: now))
        }

        if result.contains("{{timestamp}}") {
            result = result.replacingOccurrences(of: "{{timestamp}}", with: "\(Int(now.timeIntervalSince1970))")
        }

        if result.contains("{{hostname}}") {
            result = result.replacingOccurrences(of: "{{hostname}}", with: ProcessInfo.processInfo.hostName)
        }

        if result.contains("{{user}}") {
            result = result.replacingOccurrences(of: "{{user}}", with: NSUserName())
        }

        if result.contains("{{clipboard}}") {
            let clipboard = NSPasteboard.general.string(forType: .string) ?? ""
            result = result.replacingOccurrences(of: "{{clipboard}}", with: clipboard)
        }

        if result.contains("{{uuid}}") {
            // Each occurrence gets a unique UUID
            while let range = result.range(of: "{{uuid}}") {
                result = result.replacingCharacters(
                    in: range,
                    with: UUID().uuidString
                )
            }
        }

        return result
    }
}
