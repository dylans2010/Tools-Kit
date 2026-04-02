import Foundation

class JWTDecoderBackend: ObservableObject {
    @Published var token = ""
    @Published var decoded = ""
    @Published var error: String?

    func decode() {
        error = nil
        decoded = ""

        guard !token.isEmpty else {
            error = "Please enter a JWT token"
            return
        }

        let parts = token.components(separatedBy: ".")
        guard parts.count == 3 else {
            error = "Invalid JWT format. Expected 3 parts separated by dots."
            return
        }

        // Decode header and payload (parts 0 and 1)
        var decodedParts: [String: Any] = [:]

        for (index, part) in parts.prefix(2).enumerated() {
            var base64 = part
                .replacingOccurrences(of: "-", with: "+")
                .replacingOccurrences(of: "_", with: "/")

            // Add padding if needed
            let remainder = base64.count % 4
            if remainder > 0 {
                base64 += String(repeating: "=", count: 4 - remainder)
            }

            guard let data = Data(base64Encoded: base64),
                  let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                error = "Failed to decode JWT part \(index + 1)"
                return
            }

            decodedParts[index == 0 ? "header" : "payload"] = json
        }

        // Format the output
        var output = ""

        if let header = decodedParts["header"] as? [String: Any],
           let headerData = try? JSONSerialization.data(withJSONObject: header, options: [.prettyPrinted]),
           let headerString = String(data: headerData, encoding: .utf8) {
            output += "HEADER:\n\(headerString)\n\n"
        }

        if let payload = decodedParts["payload"] as? [String: Any],
           let payloadData = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted]),
           let payloadString = String(data: payloadData, encoding: .utf8) {
            output += "PAYLOAD:\n\(payloadString)\n\n"
        }

        output += "SIGNATURE:\n\(parts[2])"

        decoded = output
    }
}
