import Foundation

final class SpotifyService {

    // MARK: - Credentials (see Twist/Config/SpotifyCredentials.swift)
    private let clientID     = SpotifyCredentials.clientID
    private let clientSecret = SpotifyCredentials.clientSecret

    // MARK: - Token Cache
    private var accessToken: String?
    private var tokenExpiresAt: Date?

    private let session = URLSession.shared

    // MARK: - Public Entry Points

    func fetchPlaylist(fromString urlString: String) async throws -> SpotifyPlaylist {
        print("[Spotify] ▶ fetchPlaylist input: \(urlString)")
        let playlistID = try extractPlaylistID(from: urlString)
        print("[Spotify] ✅ extracted playlistID: \(playlistID)")
        let token = try await getAccessToken()
        print("[Spotify] ✅ got access token")
        return try await fetchPlaylist(id: playlistID, token: token)
    }

    // MARK: - Playlist ID Extraction

    /// Supports:
    ///   - https://open.spotify.com/playlist/{id}?si=...  (any extra query params OK)
    ///   - spotify:playlist:{id}
    func extractPlaylistID(from input: String) throws -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        // URI form: spotify:playlist:{id}
        if trimmed.hasPrefix("spotify:playlist:") {
            let parts = trimmed.components(separatedBy: ":")
            guard parts.count >= 3, !parts[2].isEmpty else { throw AppError.invalidURL }
            return String(parts[2])
        }

        // HTTP form: find "/playlist/" in the raw string and grab the next path segment
        // This avoids URL(string:) failures caused by unescaped characters in long share URLs.
        guard trimmed.contains("open.spotify.com") else { throw AppError.invalidURL }

        let marker = "/playlist/"
        guard let markerRange = trimmed.range(of: marker) else { throw AppError.invalidURL }

        let afterMarker = String(trimmed[markerRange.upperBound...])
        // The ID ends at the next '/', '?', '&', or '#'
        let id = afterMarker.components(separatedBy: CharacterSet(charactersIn: "/?&#")).first ?? ""
        guard !id.isEmpty else { throw AppError.invalidURL }
        return id
    }

    // MARK: - Access Token (Client Credentials)

    private func getAccessToken() async throws -> String {
        // Development Mode workaround: always fetch a fresh token.
        // Cached tokens cause 403 after the first use in Spotify's sandbox environment.
        // TODO: Re-enable caching after Extended Quota Mode is approved.
        // if let token = accessToken,
        //    let expiresAt = tokenExpiresAt,
        //    Date() < expiresAt {
        //     return token
        // }
        return try await refreshToken()
    }

    private func refreshToken() async throws -> String {
        print("[Spotify] ▶ refreshToken start")
        guard let url = URL(string: "https://accounts.spotify.com/api/token") else {
            throw AppError.spotifyNetwork
        }

        guard let credData = "\(clientID):\(clientSecret)".data(using: .utf8) else {
            throw AppError.spotifyAuth
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Basic \(credData.base64EncodedString())", forHTTPHeaderField: "Authorization")
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.httpBody = "grant_type=client_credentials".data(using: .utf8)

        let (data, response) = try await performRequest(req, networkError: .spotifyNetwork)
        if let http = response as? HTTPURLResponse {
            print("[Spotify] token HTTP status: \(http.statusCode)")
        }
        if let body = String(data: data, encoding: .utf8) {
            print("[Spotify] token response body: \(body)")
        }
        try validate(response, data: data,
                     authError: .spotifyAuth,
                     notFoundError: .spotifyNotFound,
                     rateLimitError: .spotifyRateLimit,
                     networkError: .spotifyNetwork)

        struct TokenResponse: Decodable {
            let accessToken: String
            let expiresIn: Int
            enum CodingKeys: String, CodingKey {
                case accessToken = "access_token"
                case expiresIn   = "expires_in"
            }
        }

        let parsed = try decode(TokenResponse.self, from: data)
        self.accessToken = parsed.accessToken
        self.tokenExpiresAt = Date().addingTimeInterval(TimeInterval(parsed.expiresIn - 60))
        return parsed.accessToken
    }

    // MARK: - Fetch Playlist (with Pagination)

    private func fetchPlaylist(id: String, token: String) async throws -> SpotifyPlaylist {
        // Note: Spotify's nested `fields` syntax causes 404 on some clients.
        // Fetch without fields filter and rely on Decodable ignoring unknown keys.
        guard let url = URL(string: "https://api.spotify.com/v1/playlists/\(id)") else {
            throw AppError.spotifyNetwork
        }
        print("[Spotify] ▶ fetchPlaylist URL: \(url)")

        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await performRequest(req, networkError: .spotifyNetwork)
        if let http = response as? HTTPURLResponse {
            print("[Spotify] playlist HTTP status: \(http.statusCode)")
        }
        if let body = String(data: data, encoding: .utf8) {
            print("[Spotify] playlist response body (first 500): \(body.prefix(500))")
        }
        try validate(response, data: data,
                     authError: .spotifyAuth,
                     notFoundError: .spotifyNotFound,
                     rateLimitError: .spotifyRateLimit,
                     networkError: .spotifyNetwork)

        let playlist = try decode(SpotifyPlaylist.self, from: data)

        // Collect remaining pages
        var allItems = playlist.tracks.items
        var nextURL  = playlist.tracks.next

        while let nextString = nextURL, let next = URL(string: nextString) {
            var nextReq = URLRequest(url: next)
            nextReq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (nextData, nextResponse) = try await performRequest(nextReq, networkError: .spotifyNetwork)
            try validate(nextResponse, data: nextData,
                         authError: .spotifyAuth,
                         notFoundError: .spotifyNotFound,
                         rateLimitError: .spotifyRateLimit,
                         networkError: .spotifyNetwork)

            let page = try decode(SpotifyTrackPage.self, from: nextData)
            allItems += page.items
            nextURL = page.next
        }

        return SpotifyPlaylist(
            id: playlist.id,
            name: playlist.name,
            description: playlist.description,
            owner: playlist.owner,
            tracks: SpotifyTrackPage(items: allItems, next: nil, total: playlist.tracks.total)
        )
    }

    // MARK: - Helpers

    private func performRequest(_ req: URLRequest, networkError: AppError) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: req)
        } catch {
            print("[Spotify] ❌ network error: \(error)")
            throw networkError
        }
    }

    private func validate(
        _ response: URLResponse,
        data: Data,
        authError: AppError,
        notFoundError: AppError,
        rateLimitError: AppError,
        networkError: AppError
    ) throws {
        guard let http = response as? HTTPURLResponse else { throw networkError }
        switch http.statusCode {
        case 200...299: return
        case 401:       throw authError
        case 403:       throw AppError.spotifyForbidden
        case 404:       throw notFoundError
        case 429:       throw rateLimitError
        default:        throw networkError
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("[Spotify] ❌ decode error for \(T.self): \(error)")
            throw AppError.spotifyNetwork
        }
    }
}
