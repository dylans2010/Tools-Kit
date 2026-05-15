import SwiftUI
import PhotosUI

struct OCRToolView: View {
    @StateObject private var backend = OCRToolBackend()
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Optical Character Recognition (OCR)")
                        .font(.headline)
                    Text("Select or take a photo to extract text instantly. Perfect for digitizing notes, documents, and business cards.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        VStack(spacing: 16) {
                            if let image = backend.selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 250)
                                    .cornerRadius(12)
                                    .shadow(radius: 5)
                            } else {
                                VStack(spacing: 12) {
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.system(size: 48, weight: .ultraLight))
                                        .foregroundColor(.blue)
                                    Text("Choose from Library")
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                                .background(Color(uiColor: .secondarySystemBackground))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                                        .foregroundColor(Color(.systemGray4))
                                )
                            }
                        }
                    }
                }
                .padding()

                .onChange(of: selectedItem) { _, newItem in
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
                    VStack(spacing: 16) {
                        Button(action: backend.extractText) {
                            if backend.isExtracting {
                                ProgressView().tint(.white)
                            } else {
                                Label("Extract Text", systemImage: "sparkles")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(backend.isExtracting)

                        if let error = backend.error {
                            Text(error).foregroundColor(.red).font(.caption)
                        }
                    }
                    .padding(.horizontal)
                }

                if !backend.extractedText.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Extracted Text", systemImage: "text.justify.left")
                                .font(.headline)
                            Spacer()
                            Button(action: { UIPasteboard.general.string = backend.extractedText }) {
                                Label("Copy", systemImage: "doc.on.doc")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                        }

                        TextEditor(text: .constant(backend.extractedText))
                            .frame(minHeight: 200)
                            .font(.body.monospaced())
                            .padding(8)
                            .background(Color(uiColor: .secondarySystemBackground))
                            .cornerRadius(12)
                    }
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if backend.selectedImage != nil {
                    Button(action: {
                        backend.reset()
                        selectedItem = nil
                    }) {
                        Label("Reset OCR", systemImage: "arrow.counterclockwise")
                            .foregroundColor(.red)
                    }
                    .padding(.bottom, 20)
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
