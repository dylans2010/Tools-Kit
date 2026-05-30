import SwiftUI

struct FeatureFlagView: View {
    @ObservedObject var appService = DeveloperAppService.shared
    @ObservedObject var flagService = FeatureFlagService.shared
    @State private var selectedAppID: UUID?
    @State private var showingAddFlag = false
    @State private var newFlagKey = ""
    @State private var newFlagDesc = ""

    var body: some View {
        List {
            Section("Project Selection") {
                Picker("App", selection: $selectedAppID) {
                    Text("Select an App").tag(Optional<UUID>.none)
                    ForEach(appService.apps) { app in
                        Text(app.name).tag(Optional(app.id))
                    }
                }
            }

            if let appID = selectedAppID {
                Section("Feature Flags") {
                    let filtered = flagService.flags.filter { $0.appID == appID }
                    if filtered.isEmpty {
                        Text("No feature flags defined for this project.").font(.caption).foregroundStyle(.secondary)
                    } else {
                        ForEach(filtered) { flag in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(flag.key).font(.subheadline.bold())
                                        Text(flag.description).font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Toggle("", isOn: Binding(
                                        get: { flag.isEnabled },
                                        set: { _ in Task { await flagService.toggleFlag(id: flag.id) } }
                                    ))
                                    .labelsHidden()
                                }

                                HStack {
                                    Text("Rollout: \(flag.rolloutPercentage)%").font(.caption2).foregroundStyle(.tertiary)
                                    Slider(value: Binding(
                                        get: { Double(flag.rolloutPercentage) },
                                        set: { val in Task { await flagService.updateRollout(id: flag.id, percentage: Int(val)) } }
                                    ), in: 0...100, step: 1)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    Button {
                        showingAddFlag = true
                    } label: {
                        Label("Add Feature Flag", systemImage: "flag.fill")
                    }
                }
            }
        }
        .navigationTitle("Feature Flags")
        .sheet(isPresented: $showingAddFlag) {
            addFlagSheet
        }
    }

    private var addFlagSheet: some View {
        NavigationStack {
            Form {
                Section("Flag Configuration") {
                    TextField("Key", text: $newFlagKey)
                        .autocapitalization(.none)
                    TextField("Description", text: $newFlagDesc)
                }
            }
            .navigationTitle("New Feature Flag")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingAddFlag = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        if let appID = selectedAppID {
                            Task {
                                await flagService.createFlag(appID: appID, key: newFlagKey, description: newFlagDesc)
                                await MainActor.run {
                                    newFlagKey = ""
                                    newFlagDesc = ""
                                    showingAddFlag = false
                                }
                            }
                        }
                    }
                    .disabled(newFlagKey.isEmpty)
                }
            }
        }
    }
}
