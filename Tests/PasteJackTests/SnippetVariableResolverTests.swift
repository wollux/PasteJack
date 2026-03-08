import Foundation
import Testing
@testable import PasteJack

@Suite("SnippetVariableResolver Tests")
struct SnippetVariableResolverTests {

    @Test("{{date}} resolves to yyyy-MM-dd format")
    func dateVariable() {
        let result = SnippetVariableResolver.resolve("Today: {{date}}")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let expected = dateFormatter.string(from: Date())
        #expect(result == "Today: \(expected)")
    }

    @Test("{{time}} resolves to HH:mm:ss format")
    func timeVariable() {
        let result = SnippetVariableResolver.resolve("{{time}}")
        // Just check format: two digits, colon, two digits, colon, two digits
        let parts = result.split(separator: ":")
        #expect(parts.count == 3)
        #expect(parts[0].count == 2)
        #expect(parts[1].count == 2)
        #expect(parts[2].count == 2)
    }

    @Test("{{user}} resolves to NSUserName()")
    func userVariable() {
        let result = SnippetVariableResolver.resolve("Hi {{user}}")
        #expect(result == "Hi \(NSUserName())")
    }

    @Test("{{hostname}} resolves to ProcessInfo hostname")
    func hostnameVariable() {
        let result = SnippetVariableResolver.resolve("Host: {{hostname}}")
        #expect(result == "Host: \(ProcessInfo.processInfo.hostName)")
    }

    @Test("{{timestamp}} resolves to Unix timestamp")
    func timestampVariable() {
        let before = Int(Date().timeIntervalSince1970)
        let result = SnippetVariableResolver.resolve("{{timestamp}}")
        let after = Int(Date().timeIntervalSince1970)
        guard let ts = Int(result) else {
            #expect(Bool(false), "timestamp not an integer: \(result)")
            return
        }
        #expect(ts >= before && ts <= after)
    }

    @Test("{{uuid}} generates unique UUIDs for each occurrence")
    func uuidUniqueness() {
        let result = SnippetVariableResolver.resolve("{{uuid}} {{uuid}}")
        let parts = result.split(separator: " ")
        #expect(parts.count == 2)
        #expect(parts[0] != parts[1])
        // Validate UUID format
        #expect(UUID(uuidString: String(parts[0])) != nil)
        #expect(UUID(uuidString: String(parts[1])) != nil)
    }

    @Test("Text without variables is unchanged")
    func noVariables() {
        let input = "Hello world, no variables here!"
        let result = SnippetVariableResolver.resolve(input)
        #expect(result == input)
    }

    @Test("Multiple different variables in one string")
    func multipleVariables() {
        let result = SnippetVariableResolver.resolve("{{user}}@{{hostname}}")
        #expect(result.contains("@"))
        #expect(!result.contains("{{"))
    }

    @Test("{{datetime}} resolves to yyyy-MM-dd HH:mm:ss format")
    func datetimeVariable() {
        let result = SnippetVariableResolver.resolve("{{datetime}}")
        // Should have date and time separated by space
        let parts = result.split(separator: " ")
        #expect(parts.count == 2)
        // Date part: yyyy-MM-dd
        #expect(parts[0].split(separator: "-").count == 3)
        // Time part: HH:mm:ss
        #expect(parts[1].split(separator: ":").count == 3)
    }
}
