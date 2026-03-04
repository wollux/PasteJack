import Foundation

/// Detects potentially sensitive content in text (API keys, passwords, tokens).
enum SensitiveDetector {

    struct SensitiveMatch {
        let type: MatchType
        let matchedText: String
    }

    enum MatchType: String {
        case apiKey = "API Key"
        case privateKey = "Private Key"
        case jwtToken = "JWT Token"
        case awsKey = "AWS Key"
        case highEntropy = "High-entropy String"
    }

    /// Check text for sensitive content. Returns empty array if nothing found.
    static func detect(in text: String) -> [SensitiveMatch] {
        var matches: [SensitiveMatch] = []

        // API key patterns
        let apiKeyPatterns = [
            "sk-[A-Za-z0-9]{20,}",          // OpenAI
            "pk_[a-z]+_[A-Za-z0-9]{20,}",   // Stripe
            "rk_[a-z]+_[A-Za-z0-9]{20,}",   // Stripe restricted
            "ghp_[A-Za-z0-9]{36,}",          // GitHub PAT
            "gho_[A-Za-z0-9]{36,}",          // GitHub OAuth
            "ghs_[A-Za-z0-9]{36,}",          // GitHub App
            "github_pat_[A-Za-z0-9_]{20,}",  // GitHub fine-grained
            "AKIA[A-Z0-9]{16}",              // AWS Access Key
            "xoxb-[0-9]{10,}",               // Slack bot token
            "xoxp-[0-9]{10,}",               // Slack user token
        ]

        for pattern in apiKeyPatterns {
            if let match = firstMatch(pattern: pattern, in: text) {
                matches.append(SensitiveMatch(type: .apiKey, matchedText: String(match.prefix(20)) + "…"))
            }
        }

        // Private key
        if text.contains("-----BEGIN") && text.contains("PRIVATE KEY-----") {
            matches.append(SensitiveMatch(type: .privateKey, matchedText: "-----BEGIN PRIVATE KEY-----"))
        }

        // JWT tokens
        if let match = firstMatch(pattern: "eyJ[A-Za-z0-9_-]{10,}\\.eyJ[A-Za-z0-9_-]{10,}\\.[A-Za-z0-9_-]+", in: text) {
            matches.append(SensitiveMatch(type: .jwtToken, matchedText: String(match.prefix(30)) + "…"))
        }

        // High-entropy strings (potential passwords/secrets)
        // Look for strings >20 chars with high Shannon entropy
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        for word in words where word.count >= 24 {
            let entropy = shannonEntropy(word)
            if entropy > 4.5 {
                matches.append(SensitiveMatch(type: .highEntropy, matchedText: String(word.prefix(20)) + "…"))
                break // One is enough to warn
            }
        }

        return matches
    }

    private static func firstMatch(pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range) else { return nil }
        guard let matchRange = Range(match.range, in: text) else { return nil }
        return String(text[matchRange])
    }

    private static func shannonEntropy(_ string: String) -> Double {
        let length = Double(string.count)
        guard length > 0 else { return 0 }

        var frequency: [Character: Int] = [:]
        for char in string {
            frequency[char, default: 0] += 1
        }

        var entropy = 0.0
        for count in frequency.values {
            let p = Double(count) / length
            if p > 0 {
                entropy -= p * log2(p)
            }
        }
        return entropy
    }
}
