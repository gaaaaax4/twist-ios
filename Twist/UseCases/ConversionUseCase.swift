import Foundation
import MusicKit
import UIKit

@available(iOS 16.0, *)
@MainActor
final class ConversionUseCase {

    private let ocrService        = OCRService()
    private let parser            = PlaylistParser()
    private let appleMusicService = AppleMusicService()

    /// Called on every track processed: (completedCount, totalCount)
    var onProgress: ((Int, Int) -> Void)?

    func convert(image: UIImage, playlistName: String) async throws -> ConversionResult {

        // 1. OCR
        print("[OCR] ▶ start")
        let lines = try await ocrService.recognizeText(in: image)
        print("[OCR] ── raw lines (\(lines.count)) ──────────────────")
        for (i, line) in lines.enumerated() {
            print("[OCR]  \(String(format: "%3d", i + 1)): \(line)")
        }
        print("[OCR] ────────────────────────────────────────────────")

        let tracks = parser.parse(lines: lines)
        print("[OCR] ── parsed tracks (\(tracks.count)) ─────────────")
        for (i, t) in tracks.enumerated() {
            print("[OCR]  \(String(format: "%3d", i + 1)): \"\(t.name)\" / \"\(t.artist)\"")
        }
        print("[OCR] ────────────────────────────────────────────────")
        guard !tracks.isEmpty else { throw AppError.noTracksRecognized }

        let total = tracks.count

        // 2. Request Apple Music authorization
        print("[Conversion] ▶ requesting Apple Music auth")
        try await appleMusicService.requestAuthorization()
        print("[Conversion] ✅ Apple Music authorized")

        // 3. Search each recognized track
        var matched: [Song]   = []
        var skipped: [String] = []

        for (index, track) in tracks.enumerated() {
            do {
                if let song = try await appleMusicService.findSong(for: track) {
                    print("[Conversion]   ✅ matched [\(index+1)/\(total)]: \(track.name)")
                    matched.append(song)
                } else {
                    print("[Conversion]   ⚠️ skipped [\(index+1)/\(total)]: \(track.name) – \(track.artist)")
                    skipped.append("\(track.name) – \(track.artist)")
                }
            } catch {
                print("[Conversion]   ❌ findSong error [\(index+1)/\(total)]: \(track.name) — \(error)")
                skipped.append("\(track.name) – \(track.artist)")
            }
            onProgress?(index + 1, total)
        }

        // 4. Create Apple Music playlist
        let name = playlistName.trimmingCharacters(in: .whitespaces).isEmpty
            ? "Converted Playlist" : playlistName
        print("[Conversion] ▶ creating playlist '‌\(name)' — matched: \(matched.count), skipped: \(skipped.count)")
        try await appleMusicService.createPlaylist(name: name, songs: matched)
        print("[Conversion] ✅ playlist created")

        return ConversionResult(
            playlistName:      name,
            totalTracks:       total,
            matchedCount:      matched.count,
            skippedTracks:     skipped,
            recognizedTracks:  tracks,
            rawOCRLines:       lines
        )
    }
}
