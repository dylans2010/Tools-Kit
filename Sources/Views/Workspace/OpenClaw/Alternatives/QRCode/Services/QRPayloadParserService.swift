import Foundation

class QRPayloadParserService {
    func parse(_ payload: String) throws -> QRPayload {
        guard let data = Data(base64Encoded: payload) else {
            throw QRError.invalidFormat
        }
        return try JSONDecoder().decode(QRPayload.self, from: data)
    }
}
