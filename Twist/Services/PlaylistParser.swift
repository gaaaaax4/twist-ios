import Foundation

/// Parses raw OCR lines from a Spotify playlist screenshot into (title, artist) pairs.
///
/// Supports three Spotify screenshot formats:
///   1. Web format:  Title → ・・・ → Artist   (anchor-based)
///   2. App format:  Title → Artist · Album   (middle-dot separator)
///   3. Fallback:    alternating title / artist pairs
struct PlaylistParser {

    func parse(lines: [String]) -> [RecognizedTrack] {
        // Strategy 1: ・・・ as structural anchors (Spotify web / mobile screenshots)
        let anchored = parseByAnchors(lines)
        if !anchored.isEmpty { return anchored }

        // Strategy 2: App format "Artist · Album" on the artist line
        let filtered = mergeWrappedLines(lines.filter { !isMetaLine($0) })
        let dotBased = parseDotFormat(filtered)
        if !dotBased.isEmpty { return dotBased }

        // Strategy 3: plain alternating pairs
        return parsePairFormat(filtered)
    }

    // MARK: - Strategy 1: Anchor-based (・・・ button between title and artist)

    private func parseByAnchors(_ rawLines: [String]) -> [RecognizedTrack] {
        let sepIndices = rawLines.indices.filter { isSeparatorLine(rawLines[$0]) }
        guard !sepIndices.isEmpty else { return [] }

        var result:        [(order: Int, track: RecognizedTrack)] = []
        var claimedTitles  = Set<Int>()
        var claimedArtists = Set<Int>()

        for sepIdx in sepIndices {
            // Last non-meta line before this separator → title
            let titleIdx = (0..<sepIdx).reversed()
                .first { !isMetaLine(rawLines[$0]) }
            // First non-meta line after this separator → artist
            let artistStart = ((sepIdx + 1)..<rawLines.count)
                .first { !isMetaLine(rawLines[$0]) }

            guard let ti = titleIdx, let ai = artistStart,
                  !claimedTitles.contains(ti) else { continue }

            // Merge wrapped continuation lines into artist
            var artist = rawLines[ai]
            var ni = ai + 1
            while ni < rawLines.count && isContinuation(of: artist, next: rawLines[ni]) {
                artist += rawLines[ni]; ni += 1
            }

            claimedTitles.insert(ti)
            claimedArtists.insert(ai)
            result.append((ti, RecognizedTrack(name: rawLines[ti], artist: artist)))
        }

        // Only trust content up to the last anchored artist —
        // everything after it is UI chrome (nav bar, buttons, etc.)
        guard let trustUntil = claimedArtists.max() else { return [] }

        // Orphan lines: non-meta, un-claimed, within the trusted range
        // (handles tracks whose ・・・ button wasn't OCR'd)
        var orphans: [(idx: Int, text: String)] = []
        for i in 0...trustUntil
            where !isMetaLine(rawLines[i])
               && !claimedTitles.contains(i)
               && !claimedArtists.contains(i) {
            orphans.append((i, rawLines[i]))
        }
        // Pair consecutive orphans that are adjacent in the original lines
        var j = 0
        while j + 1 < orphans.count {
            if orphans[j + 1].idx - orphans[j].idx <= 3 {
                result.append((orphans[j].idx,
                               RecognizedTrack(name: orphans[j].text,
                                               artist: orphans[j + 1].text)))
            }
            j += 2
        }

        return result.sorted { $0.order < $1.order }.map { $0.track }
    }

    // MARK: - Strategy 2: App format (Artist · Album)

    private func parseDotFormat(_ lines: [String]) -> [RecognizedTrack] {
        var tracks: [RecognizedTrack] = []
        var i = 0
        while i < lines.count {
            if i + 1 < lines.count, let artist = extractDotArtist(from: lines[i + 1]) {
                tracks.append(RecognizedTrack(name: lines[i], artist: artist))
                i += 2
                if i < lines.count && isDuration(lines[i]) { i += 1 }
            } else {
                i += 1
            }
        }
        return tracks
    }

    // MARK: - Strategy 3: Plain alternating pairs

    private func parsePairFormat(_ lines: [String]) -> [RecognizedTrack] {
        var tracks: [RecognizedTrack] = []
        var i = 0
        while i + 1 < lines.count {
            tracks.append(RecognizedTrack(name: lines[i], artist: lines[i + 1]))
            i += 2
        }
        return tracks
    }

    // MARK: - Wrapped-line merging

    private func mergeWrappedLines(_ lines: [String]) -> [String] {
        var result: [String] = []
        var i = 0
        while i < lines.count {
            let line = lines[i]
            if i + 1 < lines.count && isContinuation(of: line, next: lines[i + 1]) {
                result.append(line + lines[i + 1])
                i += 2
            } else {
                result.append(line)
                i += 1
            }
        }
        return result
    }

    /// True when `next` looks like the wrapped tail of `prev`.
    /// Only fires when `prev` is a multi-value list (contains ",").
    private func isContinuation(of prev: String, next: String) -> Bool {
        guard prev.contains(",") else { return false }
        guard let firstScalar = next.unicodeScalars.first else { return false }

        // CJK continuation: short line starting with a CJK character
        let isCJKStart = (0x3000...0x9FFF).contains(Int(firstScalar.value)) ||
                         (0xF900...0xFAFF).contains(Int(firstScalar.value))
        if isCJKStart && next.count <= 8 { return true }

        // Latin continuation: prev ends mid-list with comma, next starts with a letter
        if (prev.hasSuffix(",") || prev.hasSuffix(", ")),
           let c = next.first, c.isLetter { return true }

        return false
    }

    // MARK: - Separator-line detection (・・・ button)

    /// True for lines that are Spotify's "···" more-options button.
    private func isSeparatorLine(_ line: String) -> Bool {
        let s = line.trimmingCharacters(in: .whitespaces)
        guard !s.isEmpty, s.count <= 6 else { return false }
        // Characters allowed: katakana middle dot ・, bullet •, ellipsis …, period ., space
        let allowed = CharacterSet(charactersIn: "・•…. ")
        return s.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    // MARK: - Meta-line detection

    private func isMetaLine(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let lower   = trimmed.lowercased()

        if trimmed.isEmpty { return true }

        // ・・・ button lines
        if isSeparatorLine(trimmed) { return true }

        // Pure digits (track indices)
        if trimmed.allSatisfy({ $0.isNumber }) { return true }

        // Status-bar battery/percentage: short strings of digits + %, ', etc.
        if trimmed.count <= 5,
           trimmed.unicodeScalars.allSatisfy({
               CharacterSet.decimalDigits.union(.init(charactersIn: "%''′ ")).contains($0)
           }) { return true }

        // Clock / duration: "3:45", "22:24", "1:03:45"
        if isDuration(trimmed) { return true }

        // Symbols-only (no letters or digits at all)
        if trimmed.unicodeScalars.allSatisfy({
            !CharacterSet.letters.union(.decimalDigits).contains($0)
        }) { return true }

        // Spotify branding (catches "Spotify", "Spotify®", etc.)
        if lower.hasPrefix("spotify") { return true }

        let exactSkip: Set<String> = [
            "open app", "home", "search", "your library",
            "premium", "spotify.com", "open.spotify.com",
            "now playing", "queue", "connect to a device",
            "sign up", "log in", "get premium"
        ]
        if exactSkip.contains(lower) { return true }

        let containsSkip = [
            " song", "following", "followers",
            "liked songs", "add to playlist",
            "download", "sort by", "filter",
            "play all", "see all", "show all",
            "go to", "view album", "view artist"
        ]
        for kw in containsSkip where lower.contains(kw) { return true }

        return false
    }

    // MARK: - Helpers

    private func extractDotArtist(from line: String) -> String? {
        for sep in ["·", "•"] where line.contains(sep) {
            let artist = line.components(separatedBy: sep)
                .first?.trimmingCharacters(in: .whitespaces) ?? ""
            return artist.isEmpty ? nil : artist
        }
        return nil
    }

    private func isDuration(_ line: String) -> Bool {
        return line.range(of: #"^\d{1,2}:\d{2}(:\d{2})?$"#, options: .regularExpression) != nil
    }
}

