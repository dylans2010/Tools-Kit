import SwiftUI

struct DeveloperDatabaseManagerView: View {
    @ObservedObject var dbService = DatabaseService.shared
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var selectedAppID: UUID?

    var filteredSchemas: [DatabaseSchema] {
        dbService.schemas.filter { selectedAppID == nil || $0.appID == selectedAppID }
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

            Section("Database Schemas") {
                if filteredSchemas.isEmpty {
                    EmptyStateView(icon: "tablecells", title: "No Tables", message: "Manage your application's database schema and migrations.")
                } else {
                    ForEach(filteredSchemas) { schema in
                        VStack(alignment: .leading) {
                            Text(schema.tableName).font(.subheadline.bold())
                            Text("\(schema.columns.count) columns • v\(schema.version)").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Database Manager")
    }
}
