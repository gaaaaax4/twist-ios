import Foundation

enum AppError: LocalizedError {
    case ocrFailed
    case noTracksRecognized
    case appleMusicAuth
    case appleMusicCreate
    case appleMusicNetwork

    var errorCode: String {
        switch self {
        case .ocrFailed:           return "ERR_OCR_FAILED"
        case .noTracksRecognized:  return "ERR_NO_TRACKS"
        case .appleMusicAuth:      return "ERR_MUSIC_AUTH"
        case .appleMusicCreate:    return "ERR_MUSIC_CREATE"
        case .appleMusicNetwork:   return "ERR_MUSIC_NET"
        }
    }

    var errorDescription: String? {
        switch self {
        case .ocrFailed:
            return "Could not read text from the image. Please try a clearer screenshot. (ERR_OCR_FAILED)"
        case .noTracksRecognized:
            return "No tracks were recognized in the screenshot. Make sure it shows a Spotify playlist in list view. (ERR_NO_TRACKS)"
        case .appleMusicAuth:
            return "Apple Music access was denied. Please allow access in Settings. (ERR_MUSIC_AUTH)"
        default:
            return "Something went wrong. (\(errorCode))"
        }
    }
}
