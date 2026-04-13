import Foundation

enum AppError: LocalizedError {
    case invalidURL
    case spotifyAuth
    case spotifyForbidden
    case spotifyNotFound
    case spotifyRateLimit
    case spotifyNetwork
    case appleMusicAuth
    case appleMusicCreate
    case appleMusicNetwork

    var errorCode: String {
        switch self {
        case .invalidURL:        return "ERR_INVALID_URL"
        case .spotifyAuth:       return "ERR_SPOTIFY_401"
        case .spotifyForbidden:  return "ERR_SPOTIFY_403"
        case .spotifyNotFound:   return "ERR_SPOTIFY_404"
        case .spotifyRateLimit:  return "ERR_SPOTIFY_429"
        case .spotifyNetwork:    return "ERR_SPOTIFY_NET"
        case .appleMusicAuth:    return "ERR_MUSIC_AUTH"
        case .appleMusicCreate:  return "ERR_MUSIC_CREATE"
        case .appleMusicNetwork: return "ERR_MUSIC_NET"
        }
    }

    var errorDescription: String? {
        switch self {
        case .spotifyForbidden:
            return "This playlist could not be accessed. The Spotify API requires the app developer to have an active Spotify Premium subscription. (ERR_SPOTIFY_403)"
        default:
            return "Something went wrong. (\(errorCode))"
        }
    }
}
