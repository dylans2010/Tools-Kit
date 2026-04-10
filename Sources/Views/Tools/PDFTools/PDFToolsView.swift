import SwiftUI
import UniformTypeIdentifiers

struct PDFToolsView: View {
    @StateObject private var backend = PDFToolsBackend()
    @State private var showingFilePicker = false
    @State private var selectedURLs: [URL] = []

    var body: some View {
        VStack(spacing: 20) {
            List {
                Section(header: Text("Selected PDF Files")) {
                    if selectedURLs.isEmpty {
                        Text("No files selected").foregroundColor(.secondary)
                    } else {
                        ForEach(selectedURLs, id: \.self) { url in
                            Text(url.lastPathComponent)
                        }
                        .onDelete { indices in
                            selectedURLs.remove(atOffsets: indices)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())

            VStack(spacing: 12) {
                Button(action: { showingFilePicker = true }) {
                    Label("Add PDF Files", systemImage: "doc.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button(action: { backend.merge(pdfURLs: selectedURLs) }) {
                    if backend.isProcessing {
                        ProgressView().tint(.white)
                    } else {
                        Text("Merge PDFs")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedURLs.count < 2 || backend.isProcessing)
            }
            .padding()

            if let error = backend.error {
                Text(error).foregroundColor(.red).font(.caption)
            }

            if let output = backend.outputURL {
                ShareLink(item: output) {
                    Label("Save / Share Merged PDF", systemImage: "square.and.arrow.up")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding()

                Button("Clear") {
                    backend.reset()
                    selectedURLs = []
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("PDF Tools")
        .sheet(isPresented: $showingFilePicker) {
            FileImporterRepresentableView(allowedContentTypes: [.pdf], allowsMultipleSelection: true) { urls in
                selectedURLs.append(contentsOf: urls)
            }
        }
    }
}

struct PDFTools: Tool {
    let name = "PDF Tools"
    let icon = "doc.text.below.ecg"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Merge multiple PDF documents into a single file"
    let requiresAPI = false
    var view: AnyView { AnyView(PDFToolsView()) }
}
