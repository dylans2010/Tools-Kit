import Foundation
import Observation
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit
import CryptoKit

@Observable @MainActor
public final class QRPairingViewModel {
    public var state: PairingState = .idle
    public var qrImage: UIImage?

    public init() {}

    public func generateQRCode(host: String, port: Int) async {
        state = .discovering
        let token = generateSessionToken()
        let payload = generateQRPayload(host: host, port: port, token: token)
        qrImage = makeQRImage(from: payload, size: CGSize(width: 300, height: 300))
        state = .idle
    }

    public func handleScanResult(_ result: String) async {
        state = .connecting
        // Implementation for handling scanned result...
    }

    private func generateSessionToken() -> String {
        let key = SymmetricKey(size: .bits256)
        return key.withUnsafeBytes { Data($0).map { String(format: "%02X", $0) }.joined() }
    }

    private func generateQRPayload(host: String, port: Int, token: String) -> String {
        let exp = Date().timeIntervalSince1970 + 120
        let payload: [String: Any] = ["host": host, "port": port, "token": token, "exp": exp]
        let data = (try? JSONSerialization.data(withJSONObject: payload)) ?? Data()
        return String(data: data, encoding: .utf8) ?? ""
    }

    private func makeQRImage(from string: String, size: CGSize) -> UIImage? {
        guard let data = string.data(using: .isoLatin1) else { return nil }
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")
        guard let ciImage = filter.outputImage else { return nil }
        let sx = size.width / ciImage.extent.width
        let sy = size.height / ciImage.extent.height
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: sx, y: sy))
        return UIImage(ciImage: scaled)
    }
}
