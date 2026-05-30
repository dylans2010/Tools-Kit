import SwiftUI

struct FunnelBuilderView: View {
    @ObservedObject var appService = DeveloperAppService.shared
    @ObservedObject var store = DeveloperPersistentStore.shared
    @State private var selectedAppID: UUID?
    @State private var showingAdd = false
    @State private var newFunnelName = ""

    var body: some View {
        List {
            Section {
                Picker("App", selection: $selectedAppID) {
                    Text("Select App").tag(Optional<UUID>.none)
                    ForEach(appService.apps) { app in
                        Text(app.name).tag(Optional(app.id))
                    }
                }
            }

            Section("Conversion Funnels") {
                if selectedAppID == nil {
                    Text("Select an app to manage funnels.").foregroundStyle(.secondary)
                } else if store.funnels.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("No funnels defined for this app.").foregroundStyle(.secondary)
                        Button("Create First Funnel") { showingAdd = true }
                            .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 8)
                } else {
                    ForEach(store.funnels) { funnel in
                        VStack(alignment: .leading) {
                            Text(funnel.name).font(.headline)
                            Text("\(funnel.steps.count) steps").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .onDelete(perform: deleteFunnels)

                    Button("Create New Funnel") { showingAdd = true }
                        .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Funnel Builder")
        .sheet(isPresented: $showingAdd) {
            addFunnelSheet
        }
    }

    private var addFunnelSheet: some View {
        NavigationStack {
            Form {
                TextField("Funnel Name", text: $newFunnelName)
            }
            .navigationTitle("New Funnel")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAdd = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { addFunnel() }
                        .disabled(newFunnelName.isEmpty)
                }
            }
        }
    }

    private func addFunnel() {
        let funnel = AnalyticsFunnel(name: newFunnelName)
        var current = store.funnels
        current.append(funnel)
        store.saveFunnels(current)
        newFunnelName = ""
        showingAdd = false
    }

    private func deleteFunnels(at offsets: IndexSet) {
        var current = store.funnels
        current.remove(atOffsets: offsets)
        store.saveFunnels(current)
    }
}
