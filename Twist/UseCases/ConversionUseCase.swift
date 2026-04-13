import Foundation
import MusicKit

@available(iOS 16.0, *)
@MainActor
final class ConversionUseCase {

    private let spotifyService    = SpotifyService()
    private let appleMusicService = AppleMusicService()

    /// Called on every track processed: (completedCount, totalCount)
    var onProgress: ((Int, Int) -> Void)?

    func convert(urlString: String) async throws -> ConversionResult {

        // 1. Fetch Spotify playlist
        print("[Conversion] ▶ start — url: \(urlString)")
        let playlist = try await spotifyService.fetchPlaylist(fromString: urlString)
        let tracks   = playlist.tracks.items.compactMap(\.track)
        let total    = tracks.count
        print("[Conversion] ✅ playlist: \"\(playlist.name)\", tracks: \(total)")

        // 2. Request Apple Music authorization
        print("[Conversion] ▶ requesting Apple Music auth")
        try await appleMusicService.requestAuthorization()
        print("[Conversion] ✅ Apple Music authorized")

        // 3. Search sequentially (respects Spotify rate limits)
        var matched: [Song]   = []
        var skipped: [String] = []

        for (index, track) in tracks.enumerated() {
            do {
                if let song = try await appleMusicService.findSong(for: track) {
                    print("[Conversion]   ✅ matched [\(index+1)/\(total)]: \(track.name)")
                    matched.append(song)
                } else {
                    print("[Conversion]   ⚠️ skipped [\(index+1)/\(total)]: \(track.name) – \(track.artistName)")
                    skipped.append("\(track.name) – \(track.artistName)")
                }
            } catch {
                print("[Conversion]   ❌ findSong error [\(index+1)/\(total)]: \(track.name) — \(error)")
                skipped.append("\(track.name) – \(track.artistName)")
            }
            onProgress?(index + 1, total)
        }

        // 4. Create Apple Music playlist
        print("[Conversion] ▶ creating playlist — matched: \(matched.count), skipped: \(skipped.count)")
        let ownerName = playlist.owner.displayName ?? "Unknown"
        try await appleMusicService.createPlaylist(
            name: playlist.name,
            ownerName: ownerName,
            songs: matched
        )
        print("[Conversion] ✅ playlist created")

        return ConversionResult(
            playlistName: playlist.name,
            totalTracks: total,
            matchedCount: matched.count,
            skippedTracks: skipped
        )
    }
}
