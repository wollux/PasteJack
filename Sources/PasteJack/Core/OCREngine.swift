import Vision
import AppKit

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
    static func recognizeText(from image: CGImage) async throws -> String {
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
                    continuation.resume(returning: text)
                }
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.automaticallyDetectsLanguage = true

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.recognitionFailed(error.localizedDescription))
            }
        }
    }
}
