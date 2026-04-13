import Foundation
import MusicKit

@available(iOS 16.0, *)
final class AppleMusicService {

    // MARK: - Authorization

    func requestAuthorization() async throws {
        let status = await MusicAuthorization.request()
        guard status == .authorized else { throw AppError.appleMusicAuth }
    }

    // MARK: - Catalog Search

    /// Searches with two strategies:
    ///   1. "{title} {artist}"
    ///   2. "{title} {album}"
    /// Returns nil if nothing matches (caller should skip the track).
    func findSong(for track: SpotifyTrack) async throws -> Song? {
        let queries = [
            "\(track.name) \(track.artistName)",
            "\(track.name) \(track.album.name)"
        ]
        for query in queries {
            var req = MusicCatalogSearchRequest(term: query, types: [Song.self])
            req.limit = 1
            do {
                let res = try await req.response()
                print("[AppleMusic] search '\(query)' -> \(res.songs.count) hit(s)")
                if let song = res.songs.first {
                    print("[AppleMusic]   ✅ matched: \(song.title) – \(song.artistName)")
                    return song
                }
            } catch {
                print("[AppleMusic]   ❌ search error for '\(query)': \(error)")
                throw AppError.appleMusicNetwork
            }
        }
        print("[AppleMusic]   ⚠️ no match for: \(track.name) – \(track.artistName)")
        return nil
    }

    // MARK: - Playlist Creation

    func createPlaylist(name: String, ownerName: String, songs: [Song]) async throws {
        let finalName   = try await resolvedPlaylistName(base: name)
        let description = "Created by \(ownerName) via Twist"
        do {
            _ = try await MusicLibrary.shared.createPlaylist(
                name: finalName,
                description: description,
                items: songs
            )
        } catch {
            throw AppError.appleMusicCreate
        }
    }

    // MARK: - Duplicate Name Resolution

    /// Returns `base` if no duplicate exists, otherwise `base_2`, `base_3`, …
    private func resolvedPlaylistName(base: String) async throws -> String {
        var req = MusicLibraryRequest<Playlist>()
        let res: MusicLibraryResponse<Playlist>
        do {
            res = try await req.response()
        } catch {
            throw AppError.appleMusicNetwork
        }

        let existingNames = Set(res.items.map(\.name))
        guard existingNames.contains(base) else { return base }

        var index = 2
        while existingNames.contains("\(base)_\(index)") { index += 1 }
        return "\(base)_\(index)"
    }
}
