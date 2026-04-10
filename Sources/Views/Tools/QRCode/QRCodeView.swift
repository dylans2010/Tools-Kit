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
        VStack(spacing: 16) {
            Picker("Mode", selection: $mode) {
                Text("Generate").tag(QRMode.generate)
                Text("Scan").tag(QRMode.scan)
            }
            .pickerStyle(.segmented)

            if mode == .generate {
                QRGenerationView()
            } else {
                VStack {
                    ZStack {
                        CameraPreview(cameraService: cameraService)
                            .onAppear {
                                cameraService.delegate = scanner
                                cameraService.startSession()
                            }
                            .onDisappear {
                                cameraService.stopSession()
                            }

                        if let code = scanner.scannedCode {
                            VStack {
                                Spacer()
                                Text(code)
                                    .padding()
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(10)
                                    .padding(.bottom, 20)
                            }
                        }
                    }
                    .cornerRadius(12)
                    .padding()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding()
        .navigationTitle("QR Code")
    }
}

private struct QRGenerationView: View {
    @State private var inputText = ""
    @State private var qrCodeImage: UIImage? = nil

    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    var body: some View {
        VStack(spacing: 20) {
            TextField("Enter text or URL", text: $inputText)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button("Generate QR Code") {
                generateQRCode()
            }
            .buttonStyle(.borderedProminent)

            if let image = qrCodeImage {
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
