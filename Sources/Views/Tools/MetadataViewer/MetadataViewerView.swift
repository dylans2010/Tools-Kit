import SwiftUI
import PhotosUI
import ImageIO

struct MetadataViewerView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var metadata: [String: String] = [:]
    @State private var filter = ""

    var filteredMetadata: [(key: String, value: String)] {
        metadata.sorted(by: { $0.key < $1.key }).filter { filter.isEmpty || $0.key.localizedCaseInsensitiveContains(filter) || $0.value.localizedCaseInsensitiveContains(filter) }
    }

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
            .padding([.horizontal, .top])

            if !metadata.isEmpty {
                TextField("Filter metadata", text: $filter)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
            }

            if !filteredMetadata.isEmpty {
                List {
                    ForEach(filteredMetadata, id: \.key) { pair in
                        LabeledContent(pair.key, value: pair.value)
                    }
                }
            } else {
                Spacer()
                Text(metadata.isEmpty ? "Select an image to view EXIF and GPS metadata" : "No matching metadata")
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .navigationTitle("Metadata Viewer")
        .onChange(of: selectedItem) { _, newItem in
            Task {
                guard let data = try? await newItem?.loadTransferable(type: Data.self) else { return }
                metadata = extractMetadata(from: data)
            }
        }
    }

    private func extractMetadata(from data: Data) -> [String: String] {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else { return [:] }

        var flattened: [String: String] = [:]
        func walk(_ prefix: String, _ value: Any) {
            if let dict = value as? [CFString: Any] {
                for (k, v) in dict {
                    walk(prefix.isEmpty ? (k as String) : "\(prefix).\(k)", v)
                }
            } else {
                flattened[prefix] = "\(value)"
            }
        }

        for (k, v) in props {
            walk(k as String, v)
        }
        return flattened
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
