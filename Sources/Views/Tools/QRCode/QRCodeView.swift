import SwiftUI
import AVFoundation

@available(macOS 11.0, *)
struct QRCodeView: View {
    @StateObject private var backend = QRCodeBackend()
    @State private var mode: QRMode = .generate

    enum QRMode {
        case generate, scan
    }

    var body: some View {
        VStack {
            Picker("Mode", selection: $mode) {
                Text("Generate").tag(QRMode.generate)
                Text("Scan").tag(QRMode.scan)
            }
            .pickerStyle(.segmented)
            .padding()

            if mode == .generate {
                generationView
            } else {
                scanningView
            }
        }
        .padding()
        .navigationTitle("QR Code")
    }

    private var generationView: some View {
        VStack {
            TextField("Enter text or URL", text: $backend.inputText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Generate QR Code") {
                backend.generateQRCode()
            }
            .buttonStyle(.borderedProminent)

            if let image = backend.qrCodeImage {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding()
            } else {
                Spacer()
            }
        }
    }

    private var scanningView: some View {
        VStack {
            if backend.isScanning {
                ZStack {
                    Color.black
                    Text("Scanning Camera Preview...")
                        .foregroundColor(.white)
                }
                .frame(height: 300)
                .cornerRadius(12)
                .padding()

                Button("Stop Scanning") {
                    backend.stopScanning()
                }
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
                .padding()
            }
            Spacer()
        }
    }
}

@available(macOS 11.0, *)
struct QRCodeTool: Tool {
    let name = "QR Code Tool"
    let icon = "qrcode"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Generate and scan QR codes"

    var view: AnyView {
        AnyView(QRCodeView())
    }
}
