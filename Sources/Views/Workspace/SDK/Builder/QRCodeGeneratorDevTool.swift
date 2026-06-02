import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeGeneratorDevTool: DevTool {
    let id = "qr-code-generator"
    let name = "QR Code Generator"
    let category: DevToolCategory = .utilities
    let icon = "qrcode"
    let description = "Generate QR codes for URLs and text"

    func render() -> some View {
        QRCodeGeneratorView()
    }
}

struct QRCodeGeneratorView: View {
    @State private var text = "https://apple.com"
    @State private var qrImage: UIImage?

    var body: some View {
        VStack {
            if let img = qrImage {
                Image(uiImage: img)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: 200, height: 200)
                    .padding()
            }

            Form {
                Section("Content") {
                    TextField("Enter text or URL", text: $text)
                    Button("Generate QR") {
                        generate()
                    }
                }
            }
        }
    }

    private func generate() {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)

        if let outputImage = filter.outputImage {
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                qrImage = UIImage(cgImage: cgimg)
            }
        }
    }
}
