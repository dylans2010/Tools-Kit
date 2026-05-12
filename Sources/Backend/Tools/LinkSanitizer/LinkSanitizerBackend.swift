import Foundation

struct SanitizedLink: Sendable {
    let original: String
    let cleaned: String
    let removedParams: [String]
    var expanded: String?
}

@MainActor
final class LinkSanitizerBackend: ObservableObject {
    @Published var inputURL = ""
    @Published var result: SanitizedLink?
    @Published var isExpanding = false
    @Published var errorMessage = ""

    static let trackingParams: Set<String> = [
        "utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content",
        "fbclid", "gclid", "dclid", "gbraid", "wbraid", "msclkid",
        "mc_eid", "oly_enc_id", "oly_anon_id", "_openstat", "vero_id",
        "ref", "ref_src", "ref_url", "twclid", "igshid", "s_cid",
        "ncid", "cmpid", "cid", "zanpid", "affiliate_id"
    ]

    func sanitize() {
        let trimmed = inputURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let components = URLComponents(string: trimmed) else {
            errorMessage = "Invalid URL"
            return
        }
        errorMessage = ""

        var cleaned = components
        let original = components.queryItems ?? []
        let removed = original.filter { Self.trackingParams.contains($0.name.lowercased()) }.map { $0.name }
        cleaned.queryItems = original.filter { !Self.trackingParams.contains($0.name.lowercased()) }
        if cleaned.queryItems?.isEmpty == true { cleaned.queryItems = nil }

        let cleanedString = cleaned.url?.absoluteString ?? trimmed
        result = SanitizedLink(original: trimmed, cleaned: cleanedString, removedParams: removed)
    }

    func expandURL() {
        guard let link = result?.cleaned ?? (inputURL.isEmpty ? nil : inputURL),
              let url = URL(string: link) else { return }
        isExpanding = true
        Task {
            do {
                var request = URLRequest(url: url, timeoutInterval: 10)
                request.httpMethod = "HEAD"
                let (_, response) = try await NetworkClient.shared.data(for: request, retries: 0)
                let final = response.url?.absoluteString ?? link
                if var r = result {
                    r.expanded = final
                    result = r
                } else {
                    result = SanitizedLink(original: link, cleaned: link, removedParams: [], expanded: final)
                }
            } catch {
                errorMessage = "Could not expand: \(error.localizedDescription)"
            }
            isExpanding = false
        }
    }

    func clear() {
        inputURL = ""
        result = nil
        errorMessage = ""
    }
}
