import SwiftUI
import ImageIO

struct ImageMetadataView: View {
    @State private var imageName = "No Image Selected"
    @State private var metadata: [String: String] = [:]

    var body: some View {
        VStack(spacing: 20) {
            VStack {
                Image(systemName: "photo")
                    .font(.system(size: 64))
                    .foregroundStyle(.secondary)

                Text(imageName)
                    .font(.subheadline.bold())
            }
            .padding(40)
            .frame(maxWidth: .infinity)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding()

            Button("Select Image") {
                simulateSelection()
            }
            .buttonStyle(.bordered)

            List {
                Section("Properties") {
                    if metadata.isEmpty {
                        Text("Select an image to view metadata").font(.caption).foregroundStyle(.secondary)
                    } else {
                        ForEach(metadata.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            HStack {
                                Text(key)
                                Spacer()
                                Text(value).foregroundStyle(.secondary)
                            }
                            .font(.caption)
                        }
                    }
                }
            }
        }
        .navigationTitle("Image Metadata")
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private func simulateSelection() {
        // In a real app we use FileImporterView.
        // We will read a bundle image if available to show real metadata parsing
        if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "png"),
           let source = CGImageSourceCreateWithURL(url as CFURL, nil) {
            imageName = url.lastPathComponent
            if let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] {
                metadata["Width"] = "\(props[kCGImagePropertyPixelWidth as String] ?? 0)"
                metadata["Height"] = "\(props[kCGImagePropertyPixelHeight as String] ?? 0)"
                metadata["Color Model"] = props[kCGImagePropertyColorModel as String] as? String ?? "Unknown"
                metadata["DPI Width"] = "\(props[kCGImagePropertyDPIWidth as String] ?? 0)"
            }
        } else {
            imageName = "Default Asset"
            metadata["Info"] = "Metadata parsing ready for user-selected assets."
        }
    }
}
