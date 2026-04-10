import SwiftUI
import AVFoundation

struct QRCodeView: View {
    @StateObject private var backend = QRCodeBackend()
    @State private var mode: QRMode = .generate

    enum QRMode {
        case generate, scan
    }

    var body: some View {
        VStack(spacing: 16) {
            Picker("Mode", selection: $mode) {
                Text("Generate").tag(QRMode.generate)
                Text("Scan").tag(QRMode.scan)
            }
            .pickerStyle(.segmented)

            if mode == .generate {
                QRGenerationView(backend: backend)
            } else {
                QRScanningView(backend: backend)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding()
        .navigationTitle("QR Code")
    }
}

private struct QRGenerationView: View {
    @ObservedObject var backend: QRCodeBackend

    var body: some View {
        VStack(spacing: 20) {
            TextField("Enter text or URL", text: $backend.inputText)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button("Generate QR Code") {
                backend.generateQRCode()
            }
            .buttonStyle(.borderedProminent)

            if let image = backend.qrCodeImage {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            } else {
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private struct QRScanningView: View {
    @ObservedObject var backend: QRCodeBackend

    var body: some View {
        VStack(spacing: 20) {
            if backend.isScanning {
                ZStack {
                    if let session = backend.captureSession {
                        CameraPreview(session: session)
                    } else {
                        Color.black
                    }

                    VStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 250, height: 250)
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .cornerRadius(12)

                Button("Stop Scanning") {
                    backend.stopScanning()
                }
                .buttonStyle(.borderedProminent)
            } else {
                VStack(spacing: 20) {
                    if let code = backend.scannedCode {
                        Text("Scanned Code:")
                            .font(.headline)
                        Text(code)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    } else {
                        Text("Ready to scan")
                            .foregroundColor(.secondary)
                    }

                    Button("Start Camera Scan") {
                        backend.startScanning()
                    }
                    .buttonStyle(.borderedProminent)
                }

                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

struct QRCodeTool: Tool {
    let name = "QR Code Tool"
    let icon = "qrcode"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Generate and scan QR codes"
    let requiresAPI = false

    var view: AnyView {
        AnyView(QRCodeView())
    }
}
