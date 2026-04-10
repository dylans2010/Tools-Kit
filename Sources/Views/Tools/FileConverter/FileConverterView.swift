import SwiftUI
import UniformTypeIdentifiers

struct FileConverterView: View {
    @StateObject private var backend = FileConverterBackend()
    @State private var showingFilePicker = false

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                if let url = backend.selectedFileURL {
                    HStack {
                        Image(systemName: "doc.fill")
                            .font(.largeTitle)
                            .foregroundColor(.blue)

                        VStack(alignment: .leading) {
                            Text(url.lastPathComponent)
                                .font(.headline)
                            Text("Source File")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button(action: backend.reset) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                } else {
                    Button(action: { showingFilePicker = true }) {
                        VStack(spacing: 12) {
                            Image(systemName: "doc.badge.plus")
                                .font(.system(size: 48))
                            Text("Select Source File")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .background(Color.blue.opacity(0.05))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.blue.opacity(0.2), style: StrokeStyle(lineWidth: 2, dash: [8]))
                        )
                    }
                }

                if backend.selectedFileURL != nil {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Target Format").font(.subheadline).foregroundColor(.secondary)

                        Picker("Format", selection: $backend.targetFormat) {
                            ForEach(FileFormat.allCases) { format in
                                Label(format.rawValue, systemImage: format.icon).tag(format)
                            }
                        }
                        .pickerStyle(.menu)
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)

            if backend.isConverting {
                VStack(spacing: 12) {
                    ProgressView(value: backend.conversionProgress, total: 1.0)
                        .tint(.blue)
                    Text("Converting to \(backend.targetFormat.rawValue)... \(Int(backend.conversionProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 40)
            }

            if let error = backend.error {
                Text(error).foregroundColor(.red).font(.caption)
            }

            if let result = backend.convertedFileURL {
                VStack(spacing: 16) {
                    Label("Conversion Complete!", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.headline)

                    ShareLink(item: result) {
                        Label("Download / Share \(backend.targetFormat.rawValue)", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding()
                .background(Color.green.opacity(0.05))
                .cornerRadius(16)
                .padding(.horizontal)
            }

            Spacer()

            if backend.selectedFileURL != nil && !backend.isConverting && backend.convertedFileURL == nil {
                Button(action: backend.convert) {
                    Text("Convert File")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding()
            }
        }
        .navigationTitle("File Converter")
        .sheet(isPresented: $showingFilePicker) {
            FileImporterRepresentableView(allowedContentTypes: [.data], allowsMultipleSelection: false) { urls in
                guard let url = urls.first else { return }
                backend.selectedFileURL = url
                showingFilePicker = false
            }
        }
    }
}

struct FileConverterTool: Tool {
    let name = "Universal Converter"
    let icon = "arrow.triangle.2.circlepath.doc"
    let category = ToolCategory.conversion
    let complexity = ToolComplexity.basic
    let description = "Convert between various document and text formats"
    let requiresAPI = false
    var view: AnyView { AnyView(FileConverterView()) }
}
