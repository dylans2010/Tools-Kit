import Foundation

class JWTDecoderBackend: ObservableObject {
    @Published var token = ""
    @Published var header = ""
    @Published var payload = ""
    @Published var error = ""
    @Published var isExpired: Bool = false
    @Published var expirationDate: String = ""
    @Published var algorithm: String = ""
    @Published var issuedAt: String = ""

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .medium
        return f
    }()

    func decode() {
        error = ""
        header = ""
        payload = ""
        isExpired = false
        expirationDate = ""
        algorithm = ""
        issuedAt = ""

        let segments = token.components(separatedBy: ".")
        guard segments.count >= 2 else {
            error = "Invalid JWT: Expected at least 2 segments"
            return
        }

        header = decodeSegment(segments[0])
        payload = decodeSegment(segments[1])

        if header.isEmpty || payload.isEmpty {
            error = "Failed to decode segments. Check token format."
            return
        }

        parseHeaderFields(segments[0])
        parsePayloadFields(segments[1])
    }

    private func parseHeaderFields(_ segment: String) {
        guard let data = base64Data(segment),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        algorithm = json["alg"] as? String ?? ""
    }

    private func parsePayloadFields(_ segment: String) {
        guard let data = base64Data(segment),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

        if let exp = json["exp"] as? TimeInterval {
            let date = Date(timeIntervalSince1970: exp)
            expirationDate = dateFormatter.string(from: date)
            isExpired = date < Date()
        }

        if let iat = json["iat"] as? TimeInterval {
            issuedAt = dateFormatter.string(from: Date(timeIntervalSince1970: iat))
        }
    }

    private func base64Data(_ segment: String) -> Data? {
        var base64 = segment
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let length = Double(base64.lengthOfBytes(using: .utf8))
        let padding = Int(ceil(length / 4.0) * 4.0) - Int(length)
        base64.append(String(repeating: "=", count: padding))
        return Data(base64Encoded: base64)
    }

    private func decodeSegment(_ segment: String) -> String {
        guard let data = base64Data(segment),
              let json = try? JSONSerialization.jsonObject(with: data, options: []),
              let prettyData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted]),
              let result = String(data: prettyData, encoding: .utf8) else {
            return ""
        }
        return result
    }
}
