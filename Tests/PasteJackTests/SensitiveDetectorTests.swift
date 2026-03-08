import Testing
@testable import PasteJack

@Suite("SensitiveDetector Tests")
struct SensitiveDetectorTests {

    @Test("Detects OpenAI API key")
    func detectOpenAIKey() {
        let text = "my key is sk-abcdefghijklmnopqrstuvwxyz1234567890"
        let matches = SensitiveDetector.detect(in: text)
        #expect(!matches.isEmpty)
        #expect(matches.contains(where: { $0.type == .apiKey }))
    }

    @Test("Detects GitHub PAT")
    func detectGitHubPAT() {
        let text = "ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmn"
        let matches = SensitiveDetector.detect(in: text)
        #expect(!matches.isEmpty)
        #expect(matches.contains(where: { $0.type == .apiKey }))
    }

    @Test("Detects AWS Access Key")
    func detectAWSKey() {
        let text = "credentials: AKIAIOSFODNN7EXAMPLE"
        let matches = SensitiveDetector.detect(in: text)
        #expect(!matches.isEmpty)
        #expect(matches.contains(where: { $0.type == .apiKey }))
    }

    @Test("Detects private key header")
    func detectPrivateKey() {
        let text = """
        -----BEGIN RSA PRIVATE KEY-----
        MIIEpAIBAAKCAQEA...
        -----END RSA PRIVATE KEY-----
        """
        let matches = SensitiveDetector.detect(in: text)
        #expect(!matches.isEmpty)
        #expect(matches.contains(where: { $0.type == .privateKey }))
    }

    @Test("Detects JWT token")
    func detectJWT() {
        let text = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
        let matches = SensitiveDetector.detect(in: text)
        #expect(!matches.isEmpty)
        #expect(matches.contains(where: { $0.type == .jwtToken }))
    }

    @Test("Normal text has no matches")
    func normalText() {
        let text = "Hello world, this is a normal sentence without any secrets."
        let matches = SensitiveDetector.detect(in: text)
        #expect(matches.isEmpty)
    }

    @Test("Short text has no matches")
    func shortText() {
        let text = "abc"
        let matches = SensitiveDetector.detect(in: text)
        #expect(matches.isEmpty)
    }

    @Test("Empty text has no matches")
    func emptyText() {
        let matches = SensitiveDetector.detect(in: "")
        #expect(matches.isEmpty)
    }

    @Test("Detects GitHub fine-grained PAT")
    func detectGitHubFinegrained() {
        let text = "github_pat_ABCDEFGHIJKLMNOPQRSTUVWXYZ1234"
        let matches = SensitiveDetector.detect(in: text)
        #expect(!matches.isEmpty)
        #expect(matches.contains(where: { $0.type == .apiKey }))
    }

    @Test("Detects Slack bot token pattern")
    func detectSlackToken() {
        // Build the token dynamically to avoid GitHub push protection
        let text = ["xoxb", "0000000000", "0000000000000", "FakeTestValue0000000000"].joined(separator: "-")
        let matches = SensitiveDetector.detect(in: text)
        #expect(!matches.isEmpty)
    }
}
