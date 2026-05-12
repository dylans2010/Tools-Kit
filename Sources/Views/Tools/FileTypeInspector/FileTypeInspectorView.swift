import SwiftUI
import UniformTypeIdentifiers

struct FileTypeInspectorView: View {
    @State private var showingPicker = false
    @State private var selectedFile: URL?
    @State private var utType: UTType?

    var body: some View {
        VStack {
            if let file = selectedFile, let type = utType {
                List {
                    Section {
                        LabeledContent("Filename", value: file.lastPathComponent)
                        LabeledContent("Extension", value: file.pathExtension)
                        LabeledContent("MIME Type", value: type.preferredMIMEType ?? "Unknown")
                    } header: {
                        Text("File Identification")
                    }

                    Section {
                        LabeledContent("UTI", value: type.identifier)
                        LabeledContent("Description", value: type.localizedDescription ?? "Unknown")
                        LabeledContent("Category", value: String(describing: type.supertypes))
                    } header: {
                        Text("Type Metadata")
                    }
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "doc.questionmark")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    Text("Select a file to inspect its type")
                        .foregroundColor(.secondary)
                    Button("Select File") {
                        showingPicker = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .navigationTitle("Type Inspector")
        .sheet(isPresented: $showingPicker) {
            FileImporterRepresentableView(allowedContentTypes: [.data]) { urls in
                if let url = urls.first {
                    selectedFile = url
                    utType = UTType(filenameExtension: url.pathExtension)
                }
            }
        }
    }
}

struct FileTypeInspectorTool: Tool, Sendable {
    let name = "Type Inspector"
    let icon = "doc.questionmark"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Identify file formats and MIME types"
    let requiresAPI = false
    var view: AnyView { AnyView(FileTypeInspectorView()) }
}
