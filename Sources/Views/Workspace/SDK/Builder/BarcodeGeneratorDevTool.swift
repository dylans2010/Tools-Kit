import SwiftUI

struct BarcodeGeneratorDevTool: DevTool {
    let id = "barcode-generator"
    let name = "Barcode Generator"
    let category: DevToolCategory = .utilities
    let icon = "barcode"
    let description = "Generate 1D barcodes (Code 128) for data"

    func render() -> some View {
        BarcodeGeneratorView()
    }
}

struct BarcodeGeneratorView: View {
    @State private var text = "12345678"
    @State private var barcodeImage: UIImage?

    var body: some View {
        VStack {
            if let img = barcodeImage {
                Image(uiImage: img)
                    .interpolation(.none)
                    .resizable()
                    .frame(height: 100)
                    .padding()
            }

            Form {
                Section("Content") {
                    TextField("Enter data", text: $text)
                    Button("Generate Barcode") {
                        generate()
                    }
                }
            }
        }
    }

    private func generate() {
        let context = CIContext()
        let filter = CIFilter.code128BarcodeGenerator()
        filter.message = Data(text.utf8)

        if let outputImage = filter.outputImage {
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                barcodeImage = UIImage(cgImage: cgimg)
            }
        }
    }
}
