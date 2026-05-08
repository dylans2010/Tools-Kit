import SwiftUI
import PhotosUI

struct MetadataRemoverView: View {
    @StateObject private var backend = MetadataRemoverBackend()
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    VStack {
                        if let image = backend.inputImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .cornerRadius(12)
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)
                                Text("Select Image")
                                    .font(.headline)
                                Text("Choose an image to remove its EXIF and location metadata.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }
                    }
                }
                .onChange(of: selectedItem) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            if let image = UIImage(data: data) {
                                DispatchQueue.main.async {
                                    backend.inputImage = image
                                    backend.outputImage = nil
                                    backend.isDone = false
                                }
                            }
                        }
                    }
                }

                if backend.inputImage != nil {
                    Button(action: backend.stripMetadata) {
                        if backend.isProcessing {
                            ProgressView().tint(.white)
                        } else {
                            Text("Strip All Metadata")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(backend.isProcessing)
                    .padding(.horizontal)
                }

                if backend.isDone, let output = backend.outputImage {
                    VStack(spacing: 16) {
                        Label("Metadata Removed Successfully!", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.headline)

                        ShareLink(item: Image(uiImage: output), preview: SharePreview("Cleaned Image", image: Image(uiImage: output))) {
                            Label("Save / Share Clean Image", systemImage: "square.and.arrow.up")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                    .padding()
                }

                if backend.inputImage != nil {
                    Button("Reset") {
                        backend.reset()
                        selectedItem = nil
                    }
                    .foregroundColor(.red)
                }
            }
            .padding()
        }
        .navigationTitle("Metadata Remover")
    }
}

struct MetadataRemoverTool: Tool {
    let name = "Metadata Remover"
    let icon = "minus.square.fill"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Protect your privacy by stripping EXIF data and location from photos"
    let requiresAPI = false
    var view: AnyView { AnyView(MetadataRemoverView()) }
}
