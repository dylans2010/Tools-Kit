import Foundation

enum OAuthCallbackParser {
    static func value(_ name: String, from url: URL) -> String? {
        if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
           let value = queryItems.first(where: { $0.name == name })?.value {
            return value
        }

        guard let fragment = URLComponents(url: url, resolvingAgainstBaseURL: false)?.fragment else { return nil }
        var components = URLComponents()
        components.query = fragment
        return components.queryItems?.first(where: { $0.name == name })?.value
    }

    static func authorizationCode(from url: URL) -> String? {
        if let value = value("code", from: url), !value.isEmpty {
            return value
        }

        let decoded = url.absoluteString.removingPercentEncoding ?? url.absoluteString
        if let range = decoded.range(of: "code=") {
            let suffix = decoded[range.upperBound...]
            let code = suffix.split(separator: "&").first.map(String.init)
            if let code, !code.isEmpty {
                return code
            }
        }
        return nil
    }
}
