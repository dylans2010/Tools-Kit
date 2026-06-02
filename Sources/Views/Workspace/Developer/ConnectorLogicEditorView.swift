import SwiftUI

struct ConnectorLogicEditorView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared
    @State private var showingAdd = false
    @State private var name = ""

    var body: some View {
        List {
            Section("Logic Scripts") {
                if store.logicScripts.isEmpty {
                    Text("No scripts found.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.logicScripts) { script in
                        HStack {
                            Image(systemName: "curlybraces")
                                .foregroundStyle(.purple)
                            VStack(alignment: .leading) {
                                Text(script.name).font(.subheadline.bold())
                                Text("Modified \(script.lastModified, style: .date)").font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(script.size).font(.caption2).foregroundStyle(.tertiary)
                        }
                    }
                    .onDelete(perform: deleteScript)
                }
            }

            Section {
                Button(action: { showingAdd = true }) {
                    Label("New Logic Script", systemImage: "plus.circle")
                }
            }
        }
        .navigationTitle("Connector Logic")
        .sheet(isPresented: $showingAdd) {
            NavigationStack {
                Form {
                    TextField("Script Name", text: $name)
                }
                .navigationTitle("New Script")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAdd = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Create") { saveScript() }
                            .disabled(name.isEmpty)
                    }
                }
            }
        }
    }

    private func saveScript() {
        let new = LogicScript(name: name, size: "1.2 KB")
        var updated = store.logicScripts
        updated.append(new)
        store.saveLogicScripts(updated)
        name = ""
        showingAdd = false
    }

    private func deleteScript(at offsets: IndexSet) {
        var updated = store.logicScripts
        updated.remove(atOffsets: offsets)
        store.saveLogicScripts(updated)
    }
}
