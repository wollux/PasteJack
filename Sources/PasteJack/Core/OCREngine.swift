import Vision
import AppKit
import NaturalLanguage

/// Result from OCR containing recognized text and detected languages.
struct OCRResult {
    let text: String
    let detectedLanguages: [String]
}

/// Performs text recognition on images using Apple's Vision framework.
enum OCREngine {

    enum OCRError: Error, LocalizedError {
        case noTextFound
        case recognitionFailed(String)

        var errorDescription: String? {
            switch self {
            case .noTextFound:
                return "No text detected in the selected region."
            case .recognitionFailed(let message):
                return "OCR failed: \(message)"
            }
        }
    }

    /// Recognize text in a CGImage using VNRecognizeTextRequest.
    /// Results are sorted top-to-bottom, left-to-right.
    static func recognizeText(
        from image: CGImage,
        preferredLanguages: [String]? = nil
    ) async throws -> OCRResult {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: OCRError.recognitionFailed(error.localizedDescription))
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation],
                      !observations.isEmpty else {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }

                // Sort observations top-to-bottom (Vision uses bottom-left origin,
                // so higher Y = higher on screen → sort descending by Y)
                let sorted = observations.sorted { a, b in
                    let aY = a.boundingBox.origin.y
                    let bY = b.boundingBox.origin.y
                    // Group into lines (within 2% vertical tolerance)
                    if abs(aY - bY) < 0.02 {
                        return a.boundingBox.origin.x < b.boundingBox.origin.x
                    }
                    return aY > bY
                }

                let text = sorted.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")

                if text.isEmpty {
                    continuation.resume(throwing: OCRError.noTextFound)
                } else {
                    // Detect language using NaturalLanguage
                    let languages = detectLanguages(in: text)
                    continuation.resume(returning: OCRResult(text: text, detectedLanguages: languages))
                }
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.automaticallyDetectsLanguage = true

            if let preferredLanguages, !preferredLanguages.isEmpty {
                request.recognitionLanguages = preferredLanguages
            }

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.recognitionFailed(error.localizedDescription))
            }
        }
    }

    /// Detect dominant languages in text using NaturalLanguage framework.
    private static func detectLanguages(in text: String) -> [String] {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        let hypotheses = recognizer.languageHypotheses(withMaximum: 3)
        return hypotheses
            .sorted { $0.value > $1.value }
            .filter { $0.value > 0.1 }
            .map { $0.key.rawValue.uppercased() }
    }
}
