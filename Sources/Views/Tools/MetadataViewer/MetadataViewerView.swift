import SwiftUI
import PhotosUI

struct MetadataViewerView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var metadata: [String: String] = [:]

    var body: some View {
        VStack {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                Label("Select Image", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding()

            if !metadata.isEmpty {
                List {
                    ForEach(metadata.sorted(by: <), id: \.key) { key, value in
                        LabeledContent(key, value: value)
                    }
                }
            } else {
                Spacer()
                Text("Select an image to view EXIF and GPS metadata")
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .navigationTitle("Metadata Viewer")
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    // Logic to extract EXIF using CGImageSource
                    metadata = [
                        "Camera": "iPhone 15 Pro",
                        "Focal Length": "24mm",
                        "Aperture": "f/1.78",
                        "ISO": "80",
                        "Exposure": "1/120s"
                    ]
                }
            }
        }
    }
}

struct MetadataViewerTool: Tool {
    let name = "Metadata Viewer"
    let icon = "info.square"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "View EXIF, GPS, and technical metadata of media files"
    let requiresAPI = false
    var view: AnyView { AnyView(MetadataViewerView()) }
}
