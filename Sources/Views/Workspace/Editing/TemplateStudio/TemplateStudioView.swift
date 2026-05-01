import SwiftUI

struct TemplateStudioView: View {
    @StateObject private var manager = TemplateStudioManager.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Project Templates")) {
                    if manager.savedTemplates.isEmpty {
                        Text("No templates saved yet.")
                            .foregroundColor(.secondary)
                    }

                    ForEach(manager.savedTemplates) { template in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(template.name).bold()
                                Text(template.category).font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Apply") { }
                                .buttonStyle(.bordered)
                        }
                    }
                }
            }
            .navigationTitle("Template Studio")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
