import SwiftUI
public struct QRScannerView: View {
    @State private var pairingVM = QRPairingViewModel(); private let bridge = QRScannerBridge()
    public var body: some View { QRScannerRepresentable(bridge: bridge) { result in Task { await pairingVM.handleScanResult(result) } }.navigationTitle("Scan QR Code") }
}
struct QRScannerRepresentable: UIViewRepresentable {
    let bridge: QRScannerBridge; let onScan: (String) -> Void
    func makeUIView(context: Context) -> UIView { let view = UIView(frame: .zero); bridge.startScanning(in: view, completion: onScan); return view }
    func updateUIView(_ uiView: UIView, context: Context) {}
}
