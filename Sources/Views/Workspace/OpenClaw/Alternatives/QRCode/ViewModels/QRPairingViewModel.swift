import Foundation
#if canImport(UIKit)
import UIKit
#endif
import CoreImage
import CoreImage.CIFilterBuiltins
import Observation
import CryptoKit

@Observable @MainActor
public final class QRPairingViewModel {
    public var qrImage: UIImage?
    public var state: QRPairingState = .idle
    private let engine = QRPairingEngine()

    public init() {}

    public func generateQRCode(host: String, port: Int) {
        let token = generateSessionToken()
        let payload = "openclaw://pair?host=\(host)&port=\(port)&token=\(token)"
        self.qrImage = makeQRImage(from: payload, size: CGSize(width: 300, height: 300))
        self.state = .scanning
    }

    public func handleScanResult(_ result: String) async {
        self.state = .validatingWithGateway
        do {
            try await engine.processScanResult(result)
            self.state = .paired
        } catch {
            self.state = .validationFailed(error.localizedDescription)
        }
    }

    private func generateSessionToken() -> String {
        let key = SymmetricKey(size: .bits256)
        return key.withUnsafeBytes { Data($0).map { String(format: "%02X", $0) }.joined() }
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

        let context = CIContext()
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
