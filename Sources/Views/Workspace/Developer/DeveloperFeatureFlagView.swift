import SwiftUI

struct DeveloperFeatureFlagView: View {
    @ObservedObject var appService = DeveloperAppService.shared
    @ObservedObject var flagService = FeatureFlagService.shared
    @State private var selectedAppID: UUID?
    @State private var showingAddFlag = false
    @State private var newFlagName = ""
    @State private var newFlagKey = ""

    var filteredFlags: [FeatureFlag] {
        flagService.flags.filter { selectedAppID == nil || $0.appID == selectedAppID }
    }

    var body: some View {
        List {
            Section {
                Picker("App", selection: $selectedAppID) {
                    Text("All Projects").tag(Optional<UUID>.none)
                    ForEach(appService.apps) { app in
                        Text(app.name).tag(Optional(app.id))
                    }
                }
            }

            Section("Feature Flags") {
                if filteredFlags.isEmpty {
                    EmptyStateView(icon: "flag.slash", title: "No Feature Flags", message: "Create a feature flag to control application behavior dynamically.")
                } else {
                    ForEach(filteredFlags) { flag in
                        flagRow(flag)
                    }
                    .onDelete(perform: deleteFlags)
                }
            }
        }
        .navigationTitle("Feature Flags")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAddFlag = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingAddFlag) {
            addFlagSheet
        }
    }

    private func flagRow(_ flag: FeatureFlag) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(flag.name).font(.subheadline.bold())
                Text(flag.key).font(.caption2).monospaced().foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { flag.isEnabled },
                set: { _ in Task { try? await flagService.toggleFlag(id: flag.id) } }
            ))
        }
    }

    private var addFlagSheet: some View {
        NavigationStack {
            Form {
                Section("Flag Details") {
                    TextField("Name", text: $newFlagName)
                    TextField("Key (snake_case)", text: $newFlagKey)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
            }
            .navigationTitle("New Feature Flag")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAddFlag = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        if let appID = selectedAppID {
                            let flag = FeatureFlag(appID: appID, key: newFlagKey, name: newFlagName)
                            Task {
                                try? await flagService.createFlag(flag)
                                await MainActor.run {
                                    showingAddFlag = false
                                    newFlagName = ""
                                    newFlagKey = ""
                                }
                            }
                        }
                    }
                    .disabled(newFlagName.isEmpty || newFlagKey.isEmpty || selectedAppID == nil)
                }
            }
        }
    }

    private func deleteFlags(at offsets: IndexSet) {
        for index in offsets {
            let id = filteredFlags[index].id
            Task { try? await flagService.deleteFlag(id: id) }
        }
    }
}
