import Foundation

// MARK: - Playlist

struct SpotifyPlaylist: Decodable {
    let id: String
    let name: String
    let description: String?
    let owner: SpotifyUser
    let tracks: SpotifyTrackPage
}

// MARK: - User

struct SpotifyUser: Decodable {
    let displayName: String?

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
    }
}

// MARK: - Track Page

struct SpotifyTrackPage: Decodable {
    let items: [SpotifyTrackItem]
    let next: String?
    let total: Int
}

struct SpotifyTrackItem: Decodable {
    let track: SpotifyTrack?
}
