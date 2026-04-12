import SwiftUI

struct FileManagementTemplateSectionView: View {
    @ObservedObject var backend: FileManagementBackend
    let onDismiss: () -> Void
    @State private var selectedTemplate: FileTemplate = .html

    var body: some View {
        NavigationStack {
            Form {
                Section("Template") {
                    Picker("Template", selection: $selectedTemplate) {
                        ForEach(FileTemplate.allCases) { template in
                            Label(template.rawValue, systemImage: templateIcon(template))
                                .tag(template)
                        }
                    }
                    .pickerStyle(.inline)
                }

                Section("Preview") {
                    ScrollView {
                        Text(selectedTemplate.contents)
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 120)
                }
            }
            .navigationTitle("From Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        backend.createFromTemplate(selectedTemplate)
                        onDismiss()
                    }
                }
            }
        }
    }

    private func templateIcon(_ template: FileTemplate) -> String {
        switch template {
        case .html:   return "globe"
        case .swift:  return "swift"
        case .python: return "terminal"
        case .yaml:   return "doc.badge.gearshape"
        case .readme: return "doc.plaintext"
        }
    }
}
