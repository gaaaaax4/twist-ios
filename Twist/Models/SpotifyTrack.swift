import Foundation

struct SpotifyTrack: Decodable {
    let id: String
    let name: String
    let artists: [SpotifyArtist]
    let album: SpotifyAlbum

    var artistName: String {
        artists.first?.name ?? ""
    }
}

struct SpotifyArtist: Decodable {
    let name: String
}

struct SpotifyAlbum: Decodable {
    let name: String
}
