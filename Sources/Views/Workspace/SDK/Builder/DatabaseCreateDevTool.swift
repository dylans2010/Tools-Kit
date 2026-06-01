import SwiftUI

// MARK: - Models

struct DBTable: Identifiable, Codable {
    var id = UUID()
    var name: String
    var columns: [DBColumn]
}

struct DBColumn: Identifiable, Codable {
    var id = UUID()
    var name: String
    var type: DBColumnType
    var isPrimaryKey: Bool = false
    var isNullable: Bool = true
}

enum DBColumnType: String, CaseIterable, Codable, Identifiable {
    case string = "String / VARCHAR"
    case integer = "Integer / INT"
    case boolean = "Boolean / BOOL"
    case decimal = "Decimal / NUMERIC"
    case date = "Date / TIMESTAMP"
    case uuid = "UUID"

    var id: String { rawValue }

    var sql: String {
        switch self {
        case .string: return "VARCHAR(255)"
        case .integer: return "INTEGER"
        case .boolean: return "BOOLEAN"
        case .decimal: return "DECIMAL"
        case .date: return "TIMESTAMP"
        case .uuid: return "UUID"
        }
    }

    var swift: String {
        switch self {
        case .string: return "String"
        case .integer: return "Int"
        case .boolean: return "Bool"
        case .decimal: return "Double"
        case .date: return "Date"
        case .uuid: return "UUID"
        }
    }

    var js: String {
        switch self {
        case .string: return "string"
        case .integer: return "number"
        case .boolean: return "boolean"
        case .decimal: return "number"
        case .date: return "Date"
        case .uuid: return "string"
        }
    }
}

// MARK: - Tool Implementation

struct DatabaseCreateDevTool: DevTool {
    let id = "database-compiler"
    let name = "Database Creator"
    let category: DevToolCategory = .data
    let icon = "externaldrive.fill.badge.plus"
    let description = "Compile user-defined schemas into SQL, Swift, and JavaScript"

    func render() -> some View {
        DatabaseCreateView()
    }
}

// MARK: - View Model

@MainActor
class DatabaseCreateViewModel: ObservableObject {
    @Published var tables: [DBTable] = [
        DBTable(name: "users", columns: [
            DBColumn(name: "id", type: .uuid, isPrimaryKey: true, isNullable: false),
            DBColumn(name: "email", type: .string, isNullable: false),
            DBColumn(name: "created_at", type: .date, isNullable: false)
        ])
    ]

    func addTable() {
        tables.append(DBTable(name: "new_table", columns: [
            DBColumn(name: "id", type: .integer, isPrimaryKey: true, isNullable: false)
        ]))
    }

    func removeTable(at offsets: IndexSet) {
        tables.remove(atOffsets: offsets)
    }

    // Code Generators

    func generateSQL() -> String {
        var output = "-- PostgreSQL / SQLite Schema\n\n"
        for table in tables {
            output += "CREATE TABLE \(table.name) (\n"
            let cols = table.columns.map { col in
                var line = "  \(col.name) \(col.type.sql)"
                if col.isPrimaryKey { line += " PRIMARY KEY" }
                if !col.isNullable { line += " NOT NULL" }
                return line
            }
            output += cols.joined(separator: ",\n")
            output += "\n);\n\n"
        }
        return output
    }

    func generateSwift() -> String {
        var output = "// Swift Codable Models\n\nimport Foundation\n\n"
        for table in tables {
            let className = table.name.capitalized.replacingOccurrences(of: "s$", with: "", options: .regularExpression)
            output += "struct \(className): Codable, Identifiable {\n"
            for col in table.columns {
                let type = col.type.swift + (col.isNullable ? "?" : "")
                output += "    var \(col.name): \(type)\n"
            }
            output += "}\n\n"
        }
        return output
    }

    func generateJS() -> String {
        var output = "// JavaScript Schema Objects\n\n"
        for table in tables {
            output += "const \(table.name)Schema = {\n"
            for col in table.columns {
                output += "  \(col.name): \"\(col.type.js)\",\n"
            }
            output += "};\n\n"
        }
        return output
    }
}

// MARK: - UI

struct DatabaseCreateView: View {
    @StateObject private var viewModel = DatabaseCreateViewModel()
    @State private var selectedTab = 0
    @State private var editingTableId: UUID?

    var body: some View {
        VStack(spacing: 0) {
            Picker("View", selection: $selectedTab) {
                Text("Editor").tag(0)
                Text("SQL").tag(1)
                Text("Swift").tag(2)
                Text("JS").tag(3)
            }
            .pickerStyle(.segmented)
            .padding()
            .background(Color(uiColor: .systemBackground))

            Divider()

            if selectedTab == 0 {
                schemaEditor
            } else {
                generatedCodeView
            }
        }
    }

    private var schemaEditor: some View {
        List {
            ForEach($viewModel.tables) { $table in
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { editingTableId == table.id },
                        set: { val in editingTableId = val ? table.id : nil }
                    )
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Table Name", text: $table.name)
                            .font(.headline)
                            .textFieldStyle(.roundedBorder)

                        Text("Columns").font(.caption.bold()).foregroundStyle(.secondary)

                        ForEach($table.columns) { $col in
                            VStack(spacing: 8) {
                                HStack {
                                    TextField("Name", text: $col.name)
                                        .textFieldStyle(.roundedBorder)
                                        .font(.system(.caption, design: .monospaced))

                                    Picker("Type", selection: $col.type) {
                                        ForEach(DBColumnType.allCases) { type in
                                            Text(type.rawValue).tag(type)
                                        }
                                    }
                                    .labelsHidden()
                                    .controlSize(.small)
                                }

                                HStack {
                                    Toggle("PK", isOn: $col.isPrimaryKey).labelsHidden()
                                    Text("PK").font(.caption2)

                                    Toggle("Nullable", isOn: $col.isNullable).labelsHidden()
                                    Text("Null").font(.caption2)

                                    Spacer()

                                    Button(role: .destructive) {
                                        table.columns.removeAll(where: { $0.id == col.id })
                                    } label: {
                                        Image(systemName: "trash").font(.caption)
                                    }
                                }
                            }
                            .padding(8)
                            .background(Color.secondary.opacity(0.05))
                            .cornerRadius(6)
                        }

                        Button {
                            table.columns.append(DBColumn(name: "new_col", type: .string))
                        } label: {
                            Label("Add Column", systemImage: "plus.circle")
                                .font(.caption)
                        }
                    }
                    .padding(.vertical, 8)
                } label: {
                    HStack {
                        Image(systemName: "tablecells")
                        Text(table.name).bold()
                        Spacer()
                        Text("\(table.columns.count) cols").font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete(perform: viewModel.removeTable)

            Section {
                Button(action: viewModel.addTable) {
                    Label("Add Table", systemImage: "plus.square.fill")
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var generatedCodeView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                let code = getSelectedCode()
                HStack {
                    Text("Generated Code")
                        .font(.headline)
                    Spacer()
                    Button {
                        UIPasteboard.general.string = code
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                }

                Text(code)
                    .font(.system(size: 12, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(8)
                    .textSelection(.enabled)
            }
            .padding()
        }
    }

    private func getSelectedCode() -> String {
        switch selectedTab {
        case 1: return viewModel.generateSQL()
        case 2: return viewModel.generateSwift()
        case 3: return viewModel.generateJS()
        default: return ""
        }
    }
}
