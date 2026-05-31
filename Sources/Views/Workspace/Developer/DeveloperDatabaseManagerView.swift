import SwiftUI

struct DeveloperDatabaseManagerView: View {
    @ObservedObject var dbService = DatabaseService.shared
    @ObservedObject var appService = DeveloperAppService.shared

    @State private var selectedAppID: UUID?
    @State private var schemas: [DatabaseSchema] = []
    @State private var isRefreshing = false

    @State private var showingTableCreator = false

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
                Section {
                    Button { showingTableCreator = true } label: {
                        Label("Create New Table", systemImage: "tablecells.badge.plus")
                            .font(.subheadline.bold())
                    }
                }

                Section("Database Tables") {
                    if schemas.isEmpty && !isRefreshing {
                        Text("No tables detected for this application environment.").font(.caption).foregroundStyle(.secondary)
                    } else {
                        ForEach(schemas) { schema in
                            NavigationLink(destination: DatabaseExplorerView(schema: schema)) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(schema.tableName).font(.subheadline.bold())
                                        Text("\(schema.columns.count) columns • \(schema.rowCount) rows • v\(schema.version)").font(.system(size: 9)).foregroundStyle(.secondary)
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
        .sheet(isPresented: $showingTableCreator) {
            if let appID = selectedAppID {
                DatabaseTableCreatorView(appID: appID) {
                    refreshSchemas()
                }
            }
        }
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

struct DatabaseTableCreatorView: View {
    let appID: UUID
    let onCreated: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var tableName = ""
    @State private var columns: [DatabaseColumn] = [DatabaseColumn(name: "id", type: "INTEGER", isIndexed: true)]

    var body: some View {
        NavigationStack {
            Form {
                Section("Table Identity") {
                    TextField("Table Name", text: $tableName)
                }

                Section("Columns") {
                    ForEach($columns) { $column in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                TextField("Name", text: $column.name)
                                Spacer()
                                Picker("Type", selection: $column.type) {
                                    ForEach(["TEXT", "INTEGER", "REAL", "BLOB", "BOOLEAN"], id: \.self) { Text($0) }
                                }
                                .pickerStyle(.menu)
                            }
                            Toggle("Indexed", isOn: $column.isIndexed).font(.caption)
                        }
                    }
                    .onDelete { columns.remove(atOffsets: $0) }

                    Button {
                        columns.append(DatabaseColumn(name: "", type: "TEXT"))
                    } label: {
                        Label("Add Column", systemImage: "plus.circle")
                    }
                }
            }
            .navigationTitle("New Table")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createTable()
                    }
                    .disabled(tableName.isEmpty || columns.isEmpty || columns.contains(where: { $0.name.isEmpty }))
                }
            }
        }
    }

    private func createTable() {
        let schema = DatabaseSchema(appID: appID, tableName: tableName, columns: columns, version: 1)
        Task {
            try? await DatabaseService.shared.saveSchema(schema)
            await MainActor.run {
                onCreated()
                dismiss()
            }
        }
    }
}

struct DatabaseExplorerView: View {
    @State var schema: DatabaseSchema
    @State private var showingAddColumn = false
    @State private var newColumnName = ""
    @State private var newColumnType = "TEXT"

    var body: some View {
        List {
            Section("Stats") {
                LabeledContent("Rows", value: "\(schema.rowCount)")
                LabeledContent("Storage", value: ByteCountFormatter.string(fromByteCount: Int64(schema.storageSizeBytes), countStyle: .file))
                LabeledContent("Version", value: "v\(schema.version)")
            }

            Section("Columns") {
                ForEach(schema.columns) { column in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(column.name).font(.subheadline.bold())
                            Text(column.type).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if column.isIndexed {
                            Image(systemName: "magnifyingglass").font(.caption).foregroundStyle(.blue)
                        }
                    }
                }
            }

            Section {
                Button { showingAddColumn = true } label: { Label("Add Column", systemImage: "plus.circle") }
                Button(role: .destructive) { deleteTable() } label: { Label("Drop Table", systemImage: "trash") }
            }
        }
        .navigationTitle(schema.tableName)
        .sheet(isPresented: $showingAddColumn) {
            NavigationStack {
                Form {
                    TextField("Column Name", text: $newColumnName)
                    Picker("Type", selection: $newColumnType) {
                        ForEach(["TEXT", "INTEGER", "REAL", "BLOB", "BOOLEAN"], id: \.self) { Text($0) }
                    }
                }
                .navigationTitle("Add Column")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAddColumn = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") { addColumn() }
                            .disabled(newColumnName.isEmpty)
                    }
                }
            }
        }
    }

    private func addColumn() {
        var updated = schema
        updated.columns.append(DatabaseColumn(name: newColumnName, type: newColumnType))
        updated.version += 1
        Task {
            try? await DatabaseService.shared.saveSchema(updated)
            await MainActor.run {
                self.schema = updated
                showingAddColumn = false
                newColumnName = ""
            }
        }
    }

    private func deleteTable() {
        Task {
            try? await DatabaseService.shared.deleteSchema(id: schema.id)
            // Navigation will pop automatically if handled by parent
        }
    }
}
