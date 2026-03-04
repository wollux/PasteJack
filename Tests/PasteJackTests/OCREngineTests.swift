import Testing
import CoreGraphics
import AppKit
@testable import PasteJack

@Suite("OCREngine Tests")
struct OCREngineTests {

    /// Create a CGImage with rendered text for testing OCR.
    private func createTextImage(text: String, width: Int = 400, height: Int = 100) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        // White background
        context.setFillColor(CGColor.white)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        // Draw black text
        let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.current = nsContext

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 24),
            .foregroundColor: NSColor.black,
        ]
        let nsString = text as NSString
        nsString.draw(at: NSPoint(x: 20, y: 30), withAttributes: attributes)

        NSGraphicsContext.current = nil

        return context.makeImage()
    }

    @Test("Recognizes simple English text from image")
    func recognizeSimpleText() async throws {
        guard let image = createTextImage(text: "Hello World") else {
            Issue.record("Failed to create test image")
            return
        }

        let result = try await OCREngine.recognizeText(from: image)
        #expect(result.text.contains("Hello"))
        #expect(result.text.contains("World"))
    }

    @Test("Recognizes numbers from image")
    func recognizeNumbers() async throws {
        guard let image = createTextImage(text: "192.168.1.100") else {
            Issue.record("Failed to create test image")
            return
        }

        let result = try await OCREngine.recognizeText(from: image)
        #expect(result.text.contains("192"))
        #expect(result.text.contains("168"))
    }

    @Test("Throws noTextFound for blank image")
    func blankImageThrows() async {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: 100,
            height: 100,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return }

        // Solid white — no text
        context.setFillColor(CGColor.white)
        context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))

        guard let image = context.makeImage() else { return }

        do {
            _ = try await OCREngine.recognizeText(from: image)
            Issue.record("Expected noTextFound error")
        } catch {
            // Expected — blank image has no text
        }
    }
}
