import Foundation

struct ThreatResult {
    var url: String = ""
    var isSafe: Bool = true
    var threatType: String = ""
    var checkedAt: Date = Date()
    var source: String = ""
    var detail: String = ""
}

@MainActor
final class SafeBrowsingBackend: ObservableObject {
    @Published var urlInput = ""
    @Published var result: ThreatResult?
    @Published var isChecking = false
    @Published var errorMessage = ""
    @Published var history: [ThreatResult] = []

    func check() {
        let trimmed = urlInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        errorMessage = ""
        isChecking = true
        result = nil

        Task {
            let localResult = heuristicCheck(url: trimmed)
            if !localResult.isSafe {
                result = localResult
                history.insert(localResult, at: 0)
                isChecking = false
                return
            }
            let remoteResult = await remoteCheck(url: trimmed)
            result = remoteResult
            history.insert(remoteResult, at: 0)
            if history.count > 50 { history.removeLast() }
            isChecking = false
        }
    }

    func clear() {
        urlInput = ""
        result = nil
        errorMessage = ""
    }

    private func heuristicCheck(url: String) -> ThreatResult {
        var threat = ThreatResult(url: url, isSafe: true, checkedAt: Date(), source: "Local Heuristics")

        let suspiciousKeywords = ["phishing", "malware", "exploit", "hack", "crack",
                                   "free-iphone", "win-prize", "click-here-now",
                                   "verify-account", "suspended-account", "update-payment"]
        let suspiciousTLDs = [".xyz", ".tk", ".ml", ".ga", ".cf", ".gq", ".top", ".work"]
        let lowercased = url.lowercased()

        for keyword in suspiciousKeywords where lowercased.contains(keyword) {
            threat.isSafe = false
            threat.threatType = "SUSPICIOUS_CONTENT"
            threat.detail = "URL contains suspicious keyword: '\(keyword)'"
            return threat
        }
        for tld in suspiciousTLDs where lowercased.hasSuffix(tld) || lowercased.contains(tld + "/") {
            threat.isSafe = false
            threat.threatType = "SUSPICIOUS_TLD"
            threat.detail = "URL uses high-risk top-level domain: '\(tld)'"
            return threat
        }
        if lowercased.hasPrefix("http://") && !lowercased.hasPrefix("http://localhost") {
            threat.detail = "URL uses unencrypted HTTP"
            threat.source = "Local Heuristics"
        }
        return threat
    }

    private func remoteCheck(url: String) async -> ThreatResult {
        var threat = ThreatResult(url: url, isSafe: true, checkedAt: Date(), source: "Remote Check")
        guard let checkURL = URL(string: url) else {
            threat.detail = "Could not encode URL for check"
            return threat
        }
        do {
            var request = URLRequest(url: checkURL, timeoutInterval: 8)
            request.httpMethod = "HEAD"
            let (_, response) = try await NetworkClient.shared.data(for: request, retries: 0)
            let finalURL = response.url?.absoluteString ?? url
            if finalURL != url {
                threat.detail = "Redirects to: \(finalURL)"
            } else {
                threat.detail = "URL resolved successfully. No threats detected."
            }
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            if statusCode == 403 || statusCode == 404 {
                threat.detail += " (Status: \(statusCode))"
            }
        } catch {
            threat.detail = "Could not reach URL: \(error.localizedDescription)"
        }
        return threat
    }
}
