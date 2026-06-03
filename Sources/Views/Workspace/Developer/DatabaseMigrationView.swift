import SwiftUI

struct DatabaseMigrationView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared

    var body: some View {
        List {
            Section("Schema Migrations") {
                if store.schemaMigrations.isEmpty {
                    Text("No migrations found.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(store.schemaMigrations) { migration in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(migration.version).font(.system(size: 11, weight: .bold, design: .monospaced))
                                Text(migration.description).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(migration.status)
                                .font(.system(size: 8, weight: .black))
                                .foregroundStyle(migration.status == "Applied" ? .green : .orange)
                        }
                    }
                }
            }

            Section {
                Button {
                    var current = store.schemaMigrations
                    for i in 0..<current.count {
                        current[i].status = "Applied"
                    }
                    store.saveSchemaMigrations(current)
                } label: {
                    Label("Apply Pending Migrations", systemImage: "arrow.up.doc.fill")
                }
            }
        }
        .navigationTitle("Migrations")
        .onAppear {
            if store.schemaMigrations.isEmpty {
                store.saveSchemaMigrations([
                    SchemaMigration(version: "20240501_initial", description: "Create users and apps tables", status: "Applied"),
                    SchemaMigration(version: "20240515_indices", description: "Add performance indices to logs", status: "Pending")
                ])
            }
        }
    }
}
