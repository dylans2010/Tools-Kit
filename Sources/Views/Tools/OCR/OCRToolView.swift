import SwiftUI
import PhotosUI

struct OCRToolView: View {
    @StateObject private var backend = OCRToolBackend()
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
                                Image(systemName: "text.viewfinder")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)
                                Text("Select Image")
                                    .font(.headline)
                                Text("Tap to select an image for text extraction.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }
                    }
                }
                .onChange(of: selectedItem) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            if let image = UIImage(data: data) {
                                DispatchQueue.main.async {
                                    backend.selectedImage = image
                                    backend.extractedText = ""
                                }
                            }
                        }
                    }
                }

                if backend.selectedImage != nil {
                    Button(action: backend.extractText) {
                        if backend.isExtracting {
                            ProgressView().tint(.white)
                        } else {
                            Text("Extract Text")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(backend.isExtracting)
                    .padding(.horizontal)
                }

                if let error = backend.error {
                    Text(error).foregroundColor(.red).font(.caption)
                }

                if !backend.extractedText.isEmpty {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Extracted Text").font(.headline)
                            Spacer()
                            Button(action: { UIPasteboard.general.string = backend.extractedText }) {
                                Image(systemName: "doc.on.doc")
                            }
                        }
                        TextEditor(text: .constant(backend.extractedText))
                            .frame(minHeight: 200)
                            .padding(4)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
                    }
                    .padding()
                }

                if backend.selectedImage != nil {
                    Button("Reset") {
                        backend.reset()
                        selectedItem = nil
                    }
                    .foregroundColor(.red)
                }
            }
            .padding()
        }
        .navigationTitle("OCR Tool")
    }
}

struct OCRTool: Tool {
    let name = "OCR Tool"
    let icon = "text.viewfinder"
    let category = ToolCategory.ai
    let complexity = ToolComplexity.advanced
    let description = "Extract text from images using optical character recognition"
    let requiresAPI = false
    var view: AnyView { AnyView(OCRToolView()) }
}
