@preconcurrency import Vision
import UIKit

final class OCRService {

    /// Maximum pixel width fed to Vision. Anything larger is downsampled.
    /// Text recognition does not benefit from resolutions above ~1500 px.
    private let maxPixelWidth: CGFloat = 1500

    /// Runs Vision text recognition on `image` and returns all recognized strings
    /// sorted top-to-bottom as they appear on screen.
    func recognizeText(in image: UIImage) async throws -> [String] {
        // Downsample on a background thread before hitting Vision
        let cgImage = try await Task.detached(priority: .userInitiated) { [self] in
            guard let cg = self.downsampledCGImage(from: image) else {
                throw AppError.ocrFailed
            }
            return cg
        }.value

        return try await withCheckedThrowingContinuation { continuation in
            // Capture configuration in a nonisolated context, then pass to the handler
            let request = VNRecognizeTextRequest()
            request.recognitionLevel       = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages   = ["ja-JP", "en-US"]

            // Perform on a background thread so the main thread is never blocked
            DispatchQueue.global(qos: .userInitiated).async {
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                do {
                    try handler.perform([request])
                    
                    // Process results after successful execution
                    let lines = (request.results ?? [])
                        .filter { obs in
                            // boundingBox uses normalized coords: origin = bottom-left, (1,1) = top-right.
                            //
                            // LEFT  strip  (album thumbnails): right edge must clear the ~18 % column.
                            // TOP   strip  (Spotify navbar, status bar, hamburger ≡):
                            //   The header occupies the top ~15 % of the screen → minY > 0.83.
                            //   First track content starts below that line.
                            // BOTTOM strip (nav bar, social bar, URL bar):
                            //   These UI elements sit in the bottom ~20 % → maxY > 0.20.
                            obs.boundingBox.maxX  > 0.18 &&
                            obs.boundingBox.minY  < 0.83 &&
                            obs.boundingBox.maxY  > 0.20
                        }
                        .sorted { $0.boundingBox.minY > $1.boundingBox.minY }
                        .compactMap { $0.topCandidates(1).first?.string }
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                        .filter { !$0.isEmpty }
                    continuation.resume(returning: lines)
                } catch {
                    continuation.resume(throwing: AppError.ocrFailed)
                }
            }
        }
    }

    // MARK: - Helpers

    private func downsampledCGImage(from image: UIImage) -> CGImage? {
        guard let cg = image.cgImage else { return nil }
        let width  = CGFloat(cg.width)
        let height = CGFloat(cg.height)
        guard width > maxPixelWidth else { return cg }  // already small enough

        let scale      = maxPixelWidth / width
        let newWidth   = Int(maxPixelWidth)
        let newHeight  = Int(height * scale)
        let colorSpace = cg.colorSpace ?? CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)

        guard let ctx = CGContext(
            data: nil,
            width: newWidth, height: newHeight,
            bitsPerComponent: 8,
            bytesPerRow: newWidth * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else { return cg }

        ctx.interpolationQuality = .medium
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        return ctx.makeImage() ?? cg
    }
}
