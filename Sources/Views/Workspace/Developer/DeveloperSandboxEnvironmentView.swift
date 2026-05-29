import SwiftUI

struct DeveloperSandboxEnvironmentView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared
    @State private var showingAddSandbox = false
    @State private var newName = ""
    @State private var newURL = ""

    var body: some View {
        List {
            Section("Environments") {
                ForEach(store.sandboxes) { sandbox in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(sandbox.name).font(.subheadline.bold())
                            Text(sandbox.apiBaseURL).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if sandbox.isActive {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        } else {
                            Button("Activate") { activate(sandbox) }
                                .font(.caption.bold())
                                .buttonStyle(.bordered)
                        }
                    }
                }
                .onDelete(perform: deleteSandbox)
            }
        }
        .navigationTitle("Sandbox Environments")
        .toolbar {
            Button { showingAddSandbox = true } label: { Image(systemName: "plus") }
        }
        .sheet(isPresented: $showingAddSandbox) {
            NavigationStack {
                Form {
                    TextField("Environment Name", text: $newName)
                    TextField("API Base URL", text: $newURL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                .navigationTitle("Add Environment")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAddSandbox = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") { addSandbox() }
                            .disabled(newName.isEmpty || newURL.isEmpty)
                    }
                }
            }
        }
    }

    private func activate(_ sandbox: SandboxEnvironment) {
        var current = store.sandboxes
        for i in 0..<current.count {
            current[i].isActive = (current[i].id == sandbox.id)
        }
        store.saveSandboxes(current)
    }

    private func addSandbox() {
        let sandbox = SandboxEnvironment(name: newName, apiBaseURL: newURL)
        var current = store.sandboxes
        current.append(sandbox)
        store.saveSandboxes(current)
        showingAddSandbox = false
        newName = ""
        newURL = ""
    }

    private func deleteSandbox(at offsets: IndexSet) {
        var current = store.sandboxes
        current.remove(atOffsets: offsets)
        store.saveSandboxes(current)
    }
}
