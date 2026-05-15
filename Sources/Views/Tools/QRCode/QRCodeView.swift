import CoreImage.CIFilterBuiltins
import SwiftUI
import Vision

struct QRCodeView: View {
    @StateObject private var scanner = QRScanner()
    @StateObject private var cameraService = CameraService()
    @State private var mode: QRMode = .generate

    enum QRMode {
        case generate, scan
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Mode", selection: $mode) {
                Label("Generate", systemImage: "plus.square.dashed").tag(QRMode.generate)
                Label("Scan", systemImage: "qrcode.viewfinder").tag(QRMode.scan)
            }
            .pickerStyle(.segmented)
            .padding()

            if mode == .generate {
                QRGenerationView()
            } else {
                VStack(spacing: 16) {
                    ZStack {
                        CameraPreview(cameraService: cameraService)
                            .onAppear {
                                cameraService.delegate = scanner
                                cameraService.startSession()
                            }
                            .onDisappear {
                                cameraService.stopSession()
                            }

                        // Scanning Overlay
                        Color.black.opacity(0.3)

                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 250, height: 250)
                            .overlay(
                                Image(systemName: "viewfinder")
                                    .font(.system(size: 280, weight: .ultraLight))
                                    .foregroundColor(.white)
                            )
                    }
                    .cornerRadius(24)
                    .padding()

                    if let code = scanner.scannedCode {
                        VStack(spacing: 12) {
                            Text("Detected Code")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(code)
                                .font(.headline)
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(Color(uiColor: .secondarySystemBackground))
                                .cornerRadius(12)

                            HStack {
                                Button(action: { UIPasteboard.general.string = code }) {
                                    Label("Copy", systemImage: "doc.on.doc")
                                }
                                .buttonStyle(.bordered)

                                if let url = URL(string: code), UIApplication.shared.canOpenURL(url) {
                                    Button(action: { UIApplication.shared.open(url) }) {
                                        Label("Open", systemImage: "safari")
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                            }
                        }
                        .padding()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        Text("Point the camera at a QR code to scan it automatically.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
            }
        }
        .navigationTitle("QR Code")
    }
}

private struct QRGenerationView: View {
    @State private var inputText = ""
    @State private var qrCodeImage: UIImage? = nil

    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Enter the content you want to encode into a QR code.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    TextField("Text Or URL", text: $inputText)
                        .textFieldStyle(.roundedBorder)
                        .padding(.vertical, 4)

                    Button(action: generateQRCode) {
                        Label("Generate QR Code", systemImage: "qrcode")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(inputText.isEmpty)
                }
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(16)

                if let image = qrCodeImage {
                    VStack(spacing: 16) {
                        Image(uiImage: image)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 250, height: 250)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(radius: 5)

                        HStack {
                            Button(action: {
                                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                            }) {
                                Label("Save To Photos", systemImage: "square.and.arrow.down")
                            }
                            .buttonStyle(.bordered)

                            Button(action: {
                                let av = UIActivityViewController(activityItems: [image], applicationActivities: nil)
                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                   let vc = windowScene.windows.first?.rootViewController {
                                    vc.present(av, animated: true)
                                }
                            }) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "qrcode")
                            .font(.system(size: 80, weight: .ultraLight))
                            .foregroundColor(Color(.systemGray4))
                        Text("Your QR code will appear here.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                }
            }
            .padding()
        }
    }

    func generateQRCode() {
        let data = Data(inputText.utf8)
        filter.setValue(data, forKey: "inputMessage")

        if let outputImage = filter.outputImage {
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                qrCodeImage = UIImage(cgImage: cgimg)
            }
        }
    }
}

class QRScanner: NSObject, ObservableObject, CameraServiceDelegate {
    @Published var scannedCode: String?

    func didOutput(pixelBuffer: CVPixelBuffer) {
        let request = VNDetectBarcodesRequest { [weak self] request, error in
            guard let results = request.results as? [VNBarcodeObservation],
                  let first = results.first?.payloadStringValue else { return }

            DispatchQueue.main.async {
                self?.scannedCode = first
            }
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
}

struct QRCodeTool: Tool {
    let id = UUID()
    let requiresAPI = false
    let name = "QR Code Tool"
    let icon = "qrcode"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Generate and scan QR codes"

    var view: AnyView {
        AnyView(QRCodeView())
    }
}
