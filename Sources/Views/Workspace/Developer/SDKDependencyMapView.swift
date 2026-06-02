import SwiftUI

struct SDKDependencyMapView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared
    @State private var showingAdd = false
    @State private var name = ""
    @State private var type = "Internal"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerView

                VStack(spacing: 12) {
                    if store.sdkDependencies.isEmpty {
                        ContentUnavailableView("No Dependencies", systemImage: "link.badge.plus", description: Text("Add your first dependency to start mapping."))
                    } else {
                        ForEach(store.sdkDependencies) { node in
                            DependencyRow(node: node)
                        }
                    }
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Section {
                    Button(action: { showingAdd = true }) {
                        Label("Add Dependency", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Dependency Map")
        .background(Color(uiColor: .systemGroupedBackground))
        .sheet(isPresented: $showingAdd) {
            NavigationStack {
                Form {
                    TextField("Name", text: $name)
                    Picker("Type", selection: $type) {
                        ForEach(["System", "Internal", "External"], id: \.self) { Text($0) }
                    }
                }
                .navigationTitle("New Dependency")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAdd = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") { saveDependency() }
                            .disabled(name.isEmpty)
                    }
                }
            }
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Module Hierarchy")
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text("Total Modules: \(store.sdkDependencies.count)")
                .font(.title2.bold())
        }
    }

    private func saveDependency() {
        let new = SDKDependency(name: name, type: type)
        var updated = store.sdkDependencies
        updated.append(new)
        store.saveSDKDependencies(updated)
        name = ""
        showingAdd = false
    }
}

private struct DependencyRow: View {
    let node: SDKDependency

    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(colorForType(node.type))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(node.name).font(.subheadline.bold())
                Text(node.type).font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.primary.opacity(0.02))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func colorForType(_ type: String) -> Color {
        switch type {
        case "System": return .gray
        case "Internal": return .blue
        case "External": return .purple
        default: return .secondary
        }
    }
}
