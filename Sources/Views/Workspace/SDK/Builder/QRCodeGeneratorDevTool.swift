import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeGeneratorDevTool: DevTool {
    let id = "qr-code-gen"
    let name = "QR Code Generator"
    let category: DevToolCategory = .utilities
    let icon = "qrcode"
    let description = "Generate QR codes from text or URLs"

    func render() -> some View {
        QRCodeView()
    }
}

struct QRCodeView: View {
    @State private var text = "https://example.com"
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    var body: some View {
        VStack(spacing: 20) {
            TextField("Enter text or URL", text: $text)
                .textFieldStyle(.roundedBorder)
                .padding()

            if let image = generateQRCode(from: text) {
                #if os(iOS)
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                #elseif os(macOS)
                Image(nsImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                #endif
            }

            Spacer()
        }
        .padding()
        .navigationTitle("QR Code Generator")
    }

    #if os(iOS)
    func generateQRCode(from string: String) -> UIImage? {
        filter.message = Data(string.utf8)

        if let outputImage = filter.outputImage {
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgimg)
            }
        }

        return nil
    }
    #elseif os(macOS)
    func generateQRCode(from string: String) -> NSImage? {
        filter.message = Data(string.utf8)

        if let outputImage = filter.outputImage {
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                return NSImage(cgImage: cgimg, size: NSSize(width: outputImage.extent.width, height: outputImage.extent.height))
            }
        }

        return nil
    }
    #endif
}
