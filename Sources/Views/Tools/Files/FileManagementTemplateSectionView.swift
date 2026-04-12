import SwiftUI

struct FileManagementTemplateSectionView: View {
    @ObservedObject var backend: FileManagementBackend
    @State private var selectedTemplate: FileTemplate = .html

    var body: some View {
        ToolInputSection("Templates") {
            HStack {
                Picker("Template", selection: $selectedTemplate) {
                    ForEach(FileManagementFeatures.supportedTemplates) { template in
                        Text(template.rawValue).tag(template)
                    }
                }
                Button("Create") {
                    backend.createFromTemplate(selectedTemplate)
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
    }
}
