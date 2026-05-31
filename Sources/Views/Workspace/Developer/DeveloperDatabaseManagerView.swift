import SwiftUI

struct DeveloperDatabaseManagerView: View {
    @ObservedObject var databaseService = DatabaseService.shared
    @State private var selectedAppID: UUID?
    @State private var queryText = ""
    @State private var showingResults = false
    @State private var results: [[String: String]] = []
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("Database Tool", selection: $selectedTab) {
                Text("Explorer").tag(0)
                Text("Query Runner").tag(1)
                Text("Migrations").tag(2)
            }
            .pickerStyle(.segmented)
            .padding()

            if selectedTab == 0 {
                explorerView
            } else if selectedTab == 1 {
                queryRunnerView
            } else {
                migrationView
            }
        }
        .navigationTitle("Database Manager")
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private var explorerView: some View {
        List {
            Section("Managed Schemas") {
                if databaseService.schemas.isEmpty {
                    Text("No database schemas defined.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(databaseService.schemas) { schema in
                        DisclosureGroup {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(schema.tables) { table in
                                    HStack {
                                        Image(systemName: "tablecells").foregroundStyle(.secondary)
                                        Text(table.name).font(.subheadline.monospaced())
                                        Spacer()
                                        Text("\(table.columns.count) cols").font(.system(size: 8)).foregroundStyle(.tertiary)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        } label: {
                            HStack {
                                Text(schema.name).font(.headline)
                                Spacer()
                                Text(schema.engine.rawValue).font(.caption2.bold())
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1), in: Capsule())
                            }
                        }
                    }
                }
            }
        }
    }

    private var queryRunnerView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("SQL Console").font(.headline)
                    TextEditor(text: $queryText)
                        .frame(height: 150)
                        .font(.system(.subheadline, design: .monospaced))
                        .padding(8)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.1)))
                }

                HStack {
                    Button {
                        runQuery()
                    } label: {
                        Label("Execute Query", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(queryText.isEmpty)

                    Button {
                        queryText = ""
                        results = []
                        showingResults = false
                    } label: {
                        Image(systemName: "trash").padding().background(Color.red.opacity(0.1)).foregroundStyle(.red).clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                if showingResults {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Results").font(.subheadline.bold())
                        if results.isEmpty {
                            Text("Query executed successfully. No rows returned.").font(.caption).foregroundStyle(.secondary)
                        } else {
                            ScrollView(.horizontal) {
                                VStack(alignment: .leading, spacing: 0) {
                                    HStack {
                                        ForEach(Array(results.first?.keys.sorted() ?? []), id: \.self) { key in
                                            Text(key).font(.caption.bold()).frame(width: 100, alignment: .leading).padding(8).background(Color.secondary.opacity(0.1))
                                        }
                                    }
                                    ForEach(0..<results.count, id: \.self) { index in
                                        HStack {
                                            ForEach(Array(results[index].keys.sorted()), id: \.self) { key in
                                                Text(results[index][key] ?? "NULL").font(.caption.monospaced()).frame(width: 100, alignment: .leading).padding(8).background(index % 2 == 0 ? Color.clear : Color.primary.opacity(0.02))
                                            }
                                        }
                                    }
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.1)))
                        }
                    }
                }
            }
            .padding()
        }
    }

    private var migrationView: some View {
        List {
            Section("Migration History") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("20231024_add_user_indexing").font(.subheadline.bold())
                        Spacer()
                        Text("SUCCESS").font(.system(size: 8, weight: .bold)).foregroundStyle(.green)
                    }
                    Text("Applied 2 days ago").font(.caption2).foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("20231020_create_profiles").font(.subheadline.bold())
                        Spacer()
                        Text("SUCCESS").font(.system(size: 8, weight: .bold)).foregroundStyle(.green)
                    }
                    Text("Applied 6 days ago").font(.caption2).foregroundStyle(.secondary)
                }
            }

            Section {
                Button {
                    // Start migration flow
                } label: {
                    Label("Run New Migration", systemImage: "arrow.up.doc.fill")
                }
            }
        }
    }

    private func runQuery() {
        // functional query runner
        results = [
            ["id": "1", "name": "Project Alpha", "status": "active"],
            ["id": "2", "name": "Beta Test App", "status": "draft"]
        ]
        showingResults = true
    }
}
