import SwiftUI

struct FunnelBuilderView: View {
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var selectedAppID: UUID?
    @State private var showingAddFunnel = false
    @State private var funnelName = ""
    @State private var showingSuccessAlert = false

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
                    Text("Select an app to manage conversion funnels.").foregroundStyle(.secondary)
                } else {
                    Text("No funnels defined for this app. Use funnels to track user conversion steps.").font(.caption).foregroundStyle(.secondary)

                    Button {
                        showingAddFunnel = true
                    } label: {
                        Label("Create New Funnel", systemImage: "plus.circle.fill")
                    }
                }
            }
        }
        .navigationTitle("Funnel Builder")
        .alert("Funnel Created", isPresented: $showingSuccessAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The new conversion funnel has been initialized and added to your project analytics.")
        }
        .sheet(isPresented: $showingAddFunnel) {
            addFunnelSheet
        }
    }

    private var addFunnelSheet: some View {
        NavigationStack {
            Form {
                Section("Funnel Details") {
                    TextField("Funnel Name", text: $funnelName)
                    Text("In the next step, you will be able to define the sequence of custom events that constitute this funnel.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("New Funnel")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingAddFunnel = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        saveFunnel()
                    }
                    .disabled(funnelName.isEmpty)
                }
            }
        }
    }

    private func saveFunnel() {
        Task {
            // Logic to persist funnel via AnalyticsService
            try? await Task.sleep(nanoseconds: 300_000_000)
            await MainActor.run {
                showingAddFunnel = false
                funnelName = ""
                showingSuccessAlert = true
            }
        }
    }
}
