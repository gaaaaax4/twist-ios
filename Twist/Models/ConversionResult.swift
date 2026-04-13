import Foundation

struct ConversionResult {
    let playlistName: String
    let totalTracks: Int
    let matchedCount: Int
    let skippedTracks: [String]  // "{title} – {artist}" format
}
