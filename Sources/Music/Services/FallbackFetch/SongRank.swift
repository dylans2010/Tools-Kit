import Foundation

class SongRank {
    func findBestMatch(for song: SongFetchItem, in results: [YouTubeSearchResult]) -> String? {
        let targetTitle = song.title.lowercased()
        let targetArtist = song.artist.lowercased()

        var bestMatch: YouTubeSearchResult?
        var bestScore: Double = -1

        for result in results {
            let resultTitle = result.title.lowercased()
            let score = calculateScore(targetTitle: targetTitle, targetArtist: targetArtist, resultTitle: resultTitle)

            if score > bestScore {
                bestScore = score
                bestMatch = result
            }
        }

        // We want a decent match, let's say at least 0.4
        if let bestMatch = bestMatch, bestScore > 0.4 {
            return bestMatch.url
        }

        return nil
    }

    private func calculateScore(targetTitle: String, targetArtist: String, resultTitle: String) -> Double {
        var score: Double = 0

        // If both title and artist are in the result title, it's a very good sign
        if resultTitle.contains(targetTitle) {
            score += 0.5
        }

        if resultTitle.contains(targetArtist) {
            score += 0.3
        }

        // Penalty for things like "karaoke", "instrumental", "cover" if they are not in the target title
        let keywords = ["karaoke", "instrumental", "cover", "tutorial", "remix"]
        for keyword in keywords {
            if resultTitle.contains(keyword) && !targetTitle.contains(keyword) {
                score -= 0.2
            }
        }

        return score
    }
}
