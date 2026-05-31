import SwiftUI

struct DeveloperDatabaseManagerView: View {
    @ObservedObject var dbService = DatabaseService.shared
    @ObservedObject var appService = DeveloperAppService.shared

    @State private var selectedAppID: UUID?
    @State private var schemas: [DatabaseSchema] = []
    @State private var isRefreshing = false

    var body: some View {
        List {
            Section("Persistence Layer") {
                Picker("Application", selection: $selectedAppID) {
                    Text("Select App").tag(Optional<UUID>.none)
                    ForEach(appService.apps) { app in
                        Text(app.name).tag(Optional(app.id))
                    }
                }
            }

            if let appID = selectedAppID {
                Section("Database Schemas") {
                    if schemas.isEmpty && !isRefreshing {
                        Text("No schemas detected for this application environment.").font(.caption).foregroundStyle(.secondary)
                    } else {
                        ForEach(schemas) { schema in
                            NavigationLink(destination: Text("Schema Explorer for \(schema.tableName)")) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(schema.tableName).font(.subheadline.bold())
                                        Text("\(schema.columns.count) columns • v\(schema.version)").font(.system(size: 9)).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text("SCHEMA").font(.system(size: 8, weight: .black)).foregroundStyle(.tertiary)
                                }
                            }
                        }
                    }
                }

                Section("Operational Tasks") {
                    Button { runVacuum() } label: { Label("Optimize Storage (VACUUM)", systemImage: "sparkles") }
                    Button { createBackup() } label: { Label("Manual Backup", systemImage: "arrow.clockwise.icloud.fill") }
                }
            }
        }
        .navigationTitle("Database Manager")
        .onAppear {
            if selectedAppID == nil { selectedAppID = appService.apps.first?.id }
            refreshSchemas()
        }
        .onChange(of: selectedAppID) { _ in refreshSchemas() }
    }

    private func refreshSchemas() {
        guard let appID = selectedAppID else { return }
        isRefreshing = true
        Task {
            let fetched = try? await dbService.fetchSchemas(appID: appID)
            await MainActor.run {
                self.schemas = fetched ?? []
                self.isRefreshing = false
            }
        }
    }

    private func runVacuum() {
        guard let appID = selectedAppID else { return }
        Task { try? await dbService.vacuum(appID: appID) }
    }

    private func createBackup() {
        guard let appID = selectedAppID else { return }
        Task { try? await dbService.createBackup(appID: appID) }
    }
}
