import SwiftUI

struct SDKModuleRegistryView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared
    @State private var showingAdd = false
    @State private var name = ""
    @State private var version = "1.0.0"

    var body: some View {
        List {
            Section("Registered Modules") {
                if store.sdkModules.isEmpty {
                    Text("No modules registered.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.sdkModules) { module in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(module.name)
                                    .font(.subheadline.bold())
                                HStack {
                                    Text("v\(module.version)")
                                    Text("•")
                                    Text(module.size)
                                }
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            }
                            Spacer()
                            statusBadge(module.status)
                        }
                    }
                    .onDelete(perform: deleteModule)
                }
            }

            Section("Registry Maintenance") {
                Button(action: { showingAdd = true }) {
                    Label("Register New Module", systemImage: "plus.circle")
                }
            }
        }
        .navigationTitle("Module Registry")
        .sheet(isPresented: $showingAdd) {
            NavigationStack {
                Form {
                    TextField("Module Name", text: $name)
                    TextField("Version", text: $version)
                }
                .navigationTitle("New Module")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAdd = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Register") { saveModule() }
                            .disabled(name.isEmpty)
                    }
                }
            }
        }
    }

    private func saveModule() {
        let new = SDKModule(name: name, version: version, status: "Active", size: "120KB")
        var updated = store.sdkModules
        updated.append(new)
        store.saveSDKModules(updated)
        name = ""
        showingAdd = false
    }

    private func deleteModule(at offsets: IndexSet) {
        var updated = store.sdkModules
        updated.remove(atOffsets: offsets)
        store.saveSDKModules(updated)
    }

    private func statusBadge(_ status: String) -> some View {
        Text(status)
            .font(.system(size: 8, weight: .black))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.green.opacity(0.1))
            .foregroundStyle(.green)
            .clipShape(Capsule())
    }
}
