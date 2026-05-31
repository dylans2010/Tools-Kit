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
            Section("Management Scope") {
                Picker("App", selection: $selectedAppID) {
                    Text("All Projects").tag(Optional<UUID>.none)
                    ForEach(appService.apps) { app in
                        Text(app.name).tag(Optional(app.id))
                    }
                }
            }

            Section("Dynamic Feature Controls") {
                if filteredFlags.isEmpty {
                    EmptyStateView(icon: "flag.slash", title: "No Feature Flags", message: "Register a flag to toggle application functionality in real-time without a re-deployment.")
                } else {
                    ForEach(filteredFlags) { flag in
                        flagRow(flag)
                    }
                    .onDelete(perform: deleteFlags)
                }
            }

            Section {
                Button { showingAddFlag = true } label: {
                    Label("Create New Flag", systemImage: "flag.badge.plus.fill").font(.subheadline.bold())
                }
            }
        }
        .navigationTitle("Feature Flags")
        .sheet(isPresented: $showingAddFlag) { addFlagSheet }
        .onAppear {
            if selectedAppID == nil { selectedAppID = appService.apps.first?.id }
        }
    }

    private func flagRow(_ flag: FeatureFlag) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(flag.name).font(.subheadline.bold())
                Text(flag.key).font(.system(size: 9, design: .monospaced)).foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { flag.isEnabled },
                set: { _ in Task { try? await flagService.toggleFlag(id: flag.id) } }
            )).labelsHidden().scaleEffect(0.8)
        }
        .padding(.vertical, 4)
    }

    private var addFlagSheet: some View {
        NavigationStack {
            Form {
                Section("Project Context") {
                    Picker("App", selection: $selectedAppID) {
                        ForEach(appService.apps) { app in
                            Text(app.name).tag(Optional(app.id))
                        }
                    }
                }

                Section("Flag Configuration") {
                    TextField("Display Name", text: $newFlagName, prompt: Text("Display Name"))
                    TextField("Flag Key", text: $newFlagKey, prompt: Text("Flag Key (snake_case)"))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
            }
            .navigationTitle("New Flag")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAddFlag = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createFlag()
                    }
                    .disabled(newFlagName.isEmpty || newFlagKey.isEmpty || selectedAppID == nil)
                }
            }
        }
    }

    private func createFlag() {
        guard let appID = selectedAppID else { return }
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

    private func deleteFlags(at offsets: IndexSet) {
        for index in offsets {
            let id = filteredFlags[index].id
            Task { try? await flagService.deleteFlag(id: id) }
        }
    }
}
