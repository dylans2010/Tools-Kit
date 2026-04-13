import SwiftUI

struct IntegrationsView: View {
    @StateObject private var manager = NotebooksManager.shared
    @State private var showingCreate = false
    @State private var editingTool: IntegrationTool? = nil

    var body: some View {
        List {
            if manager.integrations.isEmpty {
                Section {
                    Text("No integrations yet. Create custom AI tools to enhance your writing.")
                        .foregroundColor(.secondary)
                        .font(.callout)
                }
            } else {
                ForEach($manager.integrations) { $tool in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(tool.name).font(.headline)
                            Text(tool.description).font(.caption).foregroundColor(.secondary).lineLimit(2)
                        }
                        Spacer()
                        Toggle("", isOn: $tool.isEnabled)
                            .labelsHidden()
                            .onChange(of: tool.isEnabled) { _ in manager.saveIntegration(tool) }
                        Button {
                            editingTool = tool
                        } label: {
                            Image(systemName: "pencil").foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { indexSet in
                    indexSet.forEach { idx in manager.deleteIntegration(manager.integrations[idx]) }
                }
            }
        }
        .navigationTitle("Integrations")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingCreate = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreate) {
            IntegrationEditorView(tool: nil)
        }
        .sheet(item: $editingTool) { tool in
            IntegrationEditorView(tool: tool)
        }
    }
}
