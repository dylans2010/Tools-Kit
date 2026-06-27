import SwiftUI
public struct QRHomeView: View {
    @State private var scannerVM = QRScannerViewModel()
    public var body: some View {
        List { Section("Method") { Text("QR Code Pairing").font(.headline) }
            Section { if scannerVM.hasPermission { NavigationLink("Open Scanner") { QRScannerView() } } else { Button("Grant Permission") { Task { await scannerVM.checkPermission() } } } }
        }.navigationTitle("QR Code").task { await scannerVM.checkPermission() }
    }
}
