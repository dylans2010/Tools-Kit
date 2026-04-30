import SwiftUI

struct MailTableView: View {
    @Environment(\.dismiss) private var dismiss

    let onInsert: (String) -> Void

    @State private var columnCount = 3
    @State private var rowCount = 2
    @State private var headers: [String] = ["Column 1", "Column 2", "Column 3"]
    @State private var rows: [[String]] = Array(repeating: ["", "", ""], count: 2)

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: max(columnCount, 1))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.workspaceBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        headerSection

                        steppersSection

                        headersGrid

                        cellsGrid
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Insert Table")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onInsert(buildMarkdownTable())
                        dismiss()
                    } label: {
                        Text("Insert")
                            .fontWeight(.bold)
                    }
                }
            }
            .onAppear {
                syncStructure(columns: columnCount, rows: rowCount)
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Table Builder", systemImage: "tablecells.fill")
                .font(.headline)
                .foregroundStyle(.blue)

            Text("Create a structured data table for your email.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.workspaceSurface, in: RoundedRectangle(cornerRadius: 12))
    }

    private var steppersSection: some View {
        VStack(spacing: 16) {
            Stepper(value: $columnCount, in: 1...6) {
                HStack {
                    Image(systemName: "rectangle.split.3x1")
                    Text("Columns: \(columnCount)")
                }
                .font(.subheadline.bold())
            }
            .onChange(of: columnCount, initial: false) { _, newValue in
                syncStructure(columns: newValue, rows: rowCount)
            }

            Stepper(value: $rowCount, in: 1...12) {
                HStack {
                    Image(systemName: "rectangle.split.1x2")
                    Text("Rows: \(rowCount)")
                }
                .font(.subheadline.bold())
            }
            .onChange(of: rowCount, initial: false) { _, newValue in
                syncStructure(columns: columnCount, rows: newValue)
            }
        }
        .padding()
        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
    }

    private var headersGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Headers", systemImage: "textformat.size")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)

            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(0..<columnCount, id: \.self) { column in
                    TextField("Header \(column + 1)", text: Binding(
                        get: { headers[safe: column] ?? "" },
                        set: { value in
                            ensureCapacity()
                            headers[column] = value
                        }
                    ))
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(10)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    private var cellsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Data Cells", systemImage: "square.grid.3x3.fill")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)

            ForEach(0..<rowCount, id: \.self) { row in
                LazyVGrid(columns: gridColumns, spacing: 12) {
                    ForEach(0..<columnCount, id: \.self) { column in
                        TextField("R\(row + 1)C\(column + 1)", text: Binding(
                            get: { rows[safe: row]?[safe: column] ?? "" },
                            set: { value in
                                ensureCapacity()
                                rows[row][column] = value
                            }
                        ))
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(10)
                        .background(Color.workspaceSurface, in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
    }

    private func ensureCapacity() {
        syncStructure(columns: columnCount, rows: rowCount)
    }

    private func syncStructure(columns: Int, rows rowTotal: Int) {
        if headers.count < columns {
            headers.append(contentsOf: (headers.count..<columns).map { "Column \($0 + 1)" })
        } else if headers.count > columns {
            headers = Array(headers.prefix(columns))
        }

        if rows.count < rowTotal {
            for _ in rows.count..<rowTotal {
                rows.append(Array(repeating: "", count: columns))
            }
        } else if rows.count > rowTotal {
            rows = Array(rows.prefix(rowTotal))
        }

        for index in rows.indices {
            if rows[index].count < columns {
                rows[index].append(contentsOf: Array(repeating: "", count: columns - rows[index].count))
            } else if rows[index].count > columns {
                rows[index] = Array(rows[index].prefix(columns))
            }
        }
    }

    private func buildMarkdownTable() -> String {
        let sanitizedHeaders = headers.prefix(columnCount).map(sanitize)
        let headerLine = "| " + sanitizedHeaders.joined(separator: " | ") + " |"
        let dividerLine = "| " + Array(repeating: "---", count: columnCount).joined(separator: " | ") + " |"
        let bodyLines = rows.prefix(rowCount).map { row in
            "| " + row.prefix(columnCount).map(sanitize).joined(separator: " | ") + " |"
        }
        return ([headerLine, dividerLine] + bodyLines).joined(separator: "\n")
    }

    private func sanitize(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.replacingOccurrences(of: "|", with: "\\|")
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= startIndex && index < endIndex else { return nil }
        return self[index]
    }
}
