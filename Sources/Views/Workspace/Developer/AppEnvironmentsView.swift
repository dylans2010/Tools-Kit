import SwiftUI

struct AppEnvironmentsView: View {
    let appID: UUID
    @ObservedObject var appService = DeveloperAppService.shared
    @ObservedObject var keyService = APIKeyService.shared
    @State private var showingAdd = false
    @State private var newName = ""
    @State private var newURL = "https://api.example.com"

    var app: DeveloperApp? {
        appService.apps.first { $0.id == appID }
    }

    var body: some View {
        List {
            if let app = app {
                ForEach(app.environments) { env in
                    Section(env.name) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("API Base URL").font(.caption.bold()).foregroundStyle(.secondary)
                            Text(env.apiBaseURL).font(.subheadline)

                            Divider().padding(.vertical, 4)

                            Text("Assigned Keys").font(.caption.bold()).foregroundStyle(.secondary)
                            if env.assignedKeyIDs.isEmpty {
                                Text("No keys assigned.").font(.caption).foregroundStyle(.secondary)
                            } else {
                                ForEach(env.assignedKeyIDs, id: \.self) { keyID in
                                    if let key = keyService.keys.first(where: { $0.id == keyID }) {
                                        HStack {
                                            Text(key.label).font(.caption.bold())
                                            Spacer()
                                            Text(key.maskedValue).font(.system(size: 8, design: .monospaced))
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .navigationTitle("Environments")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAdd = true } label: { Image(systemName: "plus") }
                    .disabled(app == nil)
            }
        }
        .sheet(isPresented: $showingAdd) {
            addEnvSheet
        }
    }

    private var addEnvSheet: some View {
        NavigationStack {
            Form {
                TextField("Environment Name", text: $newName)
                TextField("Base URL", text: $newURL)
            }
            .navigationTitle("New Environment")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAdd = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addEnv() }
                        .disabled(newName.isEmpty)
                }
            }
        }
    }

    private func addEnv() {
        guard var app = app else { return }
        let env = AppEnvironment(name: newName, apiBaseURL: newURL)
        app.environments.append(env)
        Task {
            try? await appService.updateApp(app)
            await MainActor.run {
                showingAdd = false
                newName = ""
            }
        }
    }
}
