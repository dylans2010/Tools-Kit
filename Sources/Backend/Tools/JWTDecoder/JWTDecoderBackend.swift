import Foundation

class JWTDecoderBackend: ObservableObject {
    @Published var token = ""
    @Published var header = ""
    @Published var payload = ""
    @Published var error = ""

    func decode() {
        error = ""
        header = ""
        payload = ""

        let segments = token.components(separatedBy: ".")
        guard segments.count >= 2 else {
            error = "Invalid JWT: Expected at least 2 segments"
            return
        }

        header = decodeSegment(segments[0])
        payload = decodeSegment(segments[1])

        if header.isEmpty || payload.isEmpty {
            error = "Failed to decode segments. Check token format."
        }
    }

    private func decodeSegment(_ segment: String) -> String {
        var base64 = segment
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let length = Double(base64.lengthOfBytes(using: .utf8))
        let requiredPadding = Int(ceil(length / 4.0) * 4.0) - Int(length)
        base64.append(String(repeating: "=", count: requiredPadding))

        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data, options: []),
              let prettyData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted]),
              let result = String(data: prettyData, encoding: .utf8) else {
            return ""
        }

        return result
    }
}
