import Foundation

struct ConversionResult {
    let playlistName: String
    let totalTracks: Int
    let matchedCount: Int
    let skippedTracks: [String]          // "{title} – {artist}" (not found on Apple Music)
    let recognizedTracks: [RecognizedTrack]  // OCR-parsed tracks
    let rawOCRLines: [String]            // raw Vision output before any filtering

    static let empty = ConversionResult(
        playlistName: "",
        totalTracks: 0,
        matchedCount: 0,
        skippedTracks: [],
        recognizedTracks: [],
        rawOCRLines: []
    )
}
