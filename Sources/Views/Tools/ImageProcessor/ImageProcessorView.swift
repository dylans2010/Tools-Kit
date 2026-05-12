import SwiftUI
import PhotosUI

struct ImageProcessorView: View {
    @StateObject private var backend = ImageProcessorBackend()
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    VStack {
                        if let image = backend.selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .cornerRadius(12)
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)
                                Text("No Image Selected")
                                    .font(.headline)
                                Text("Tap to select an image to compress.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }
                    }
                }
                .onChange(of: selectedItem) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadItemContent(type: .data) {
                            if let image = UIImage(data: data) {
                                backend.setImage(image)
                            }
                        }
                    }
                }

                if backend.selectedImage != nil {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Compression Quality: \(Int(backend.compressionQuality * 100))%")
                            .font(.subheadline)

                        Slider(value: $backend.compressionQuality, in: 0.1...1.0)

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Original Size").font(.caption).foregroundColor(.secondary)
                                Text(formatBytes(backend.originalSize)).bold()
                            }
                            Spacer()
                            if backend.processedSize > 0 {
                                VStack(alignment: .trailing) {
                                    Text("Compressed Size").font(.caption).foregroundColor(.secondary)
                                    Text(formatBytes(backend.processedSize)).bold().foregroundColor(.green)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)

                        Button(action: backend.compressImage) {
                            if backend.isProcessing {
                                ProgressView().tint(.white)
                            } else {
                                Text("Compress Image")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(backend.isProcessing)
                    }
                    .padding()
                }

                if let processed = backend.processedImage {
                    VStack(alignment: .leading) {
                        Text("Preview").font(.headline)
                        Image(uiImage: processed)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(12)

                        ShareLink(item: Image(uiImage: processed), preview: SharePreview("Compressed Image", image: Image(uiImage: processed))) {
                            Label("Save / Share", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                }
            }
            .padding()
        }
        .navigationTitle("Image Processor")
    }

    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// Simple Data Extension for older iOS support in Task block if needed
extension PhotosPickerItem {
    func loadItemContent(type: UTType) async throws -> Data? {
        try await self.loadTransferable(type: Data.self)
    }
}

struct ImageProcessorTool: Tool, Sendable {
    let name = "Image Processor"
    let icon = "paintbrush"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Compress and optimize images for web or sharing"
    let requiresAPI = false
    var view: AnyView { AnyView(ImageProcessorView()) }
}
