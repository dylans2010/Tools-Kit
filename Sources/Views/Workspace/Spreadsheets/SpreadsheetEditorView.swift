import SwiftUI

struct SpreadsheetEditorView: View {
    let spreadsheet: Spreadsheet
    @ObservedObject var manager: SpreadsheetsManager

    @State private var sheet: Spreadsheet
    @State private var selectedCell: (row: Int, col: Int)? = nil
    @State private var showingCellEditor = false
    @State private var showingAI = false
    @State private var aiResult = ""
    @State private var aiLoading = false

    private let colWidth: CGFloat = 90
    private let rowHeight: CGFloat = 36
    private let headerWidth: CGFloat = 44

    init(spreadsheet: Spreadsheet, manager: SpreadsheetsManager) {
        self.spreadsheet = spreadsheet
        self.manager = manager
        _sheet = State(initialValue: spreadsheet)
    }

    var body: some View {
        VStack(spacing: 0) {
            FormulaBarView(
                selectedCell: selectedCell,
                sheet: sheet,
                onFormulaChanged: { newFormula in
                    guard let sel = selectedCell else { return }
                    updateCell(row: sel.row, col: sel.col, formula: newFormula)
                }
            )

            SpreadsheetToolbarView(
                onAddRow: { addRow() },
                onAddColumn: { addColumn() },
                onDeleteRow: {
                    if let sel = selectedCell { deleteRow(sel.row) }
                },
                onDeleteColumn: {
                    if let sel = selectedCell { deleteColumn(sel.col) }
                },
                onAI: { showingAI = true }
            )

            Divider()

            ScrollView([.horizontal, .vertical]) {
                VStack(spacing: 0) {
                    // Column headers row
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(width: headerWidth, height: rowHeight)
                            .border(Color(.systemGray4), width: 0.5)

                        ForEach(0..<sheet.columns, id: \.self) { col in
                            Text(columnLabel(col))
                                .font(.caption.bold())
                                .frame(width: colWidth, height: rowHeight)
                                .background(Color(.systemGray5))
                                .border(Color(.systemGray4), width: 0.5)
                        }
                    }

                    // Data rows
                    ForEach(0..<sheet.rows, id: \.self) { row in
                        HStack(spacing: 0) {
                            Text("\(row + 1)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: headerWidth, height: rowHeight)
                                .background(Color(.systemGray5))
                                .border(Color(.systemGray4), width: 0.5)

                            ForEach(0..<sheet.columns, id: \.self) { col in
                                cellView(row: row, col: col)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(sheet.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingCellEditor) {
            if let sel = selectedCell {
                CellEditorView(
                    cell: sheet.cells[sel.row][sel.col],
                    address: "\(columnLabel(sel.col))\(sel.row + 1)",
                    onSave: { value, formula in
                        updateCell(row: sel.row, col: sel.col, value: value, formula: formula)
                        showingCellEditor = false
                    },
                    onCancel: { showingCellEditor = false }
                )
            }
        }
        .sheet(isPresented: $showingAI) {
            aiSheet
        }
    }

    private func cellView(row: Int, col: Int) -> some View {
        let isSelected = selectedCell?.row == row && selectedCell?.col == col
        let cell = sheet.cells[row][col]
        let display = manager.compute(cell: cell, allCells: sheet.cells)

        return Text(display)
            .font(.system(size: 13))
            .lineLimit(1)
            .frame(width: colWidth, height: rowHeight, alignment: .leading)
            .padding(.leading, 4)
            .background(isSelected ? Color.blue.opacity(0.15) : Color(.systemBackground))
            .border(isSelected ? Color.blue : Color(.systemGray4), width: isSelected ? 1.5 : 0.5)
            .onTapGesture {
                selectedCell = (row, col)
                showingCellEditor = true
            }
    }

    // MARK: - Editing

    private func updateCell(row: Int, col: Int, value: String? = nil, formula: String? = nil) {
        guard row < sheet.cells.count, col < sheet.cells[row].count else { return }
        if let v = value { sheet.cells[row][col].value = v }
        sheet.cells[row][col].formula = formula?.isEmpty == false ? formula : nil
        sheet.cells[row][col].computedValue = manager.compute(cell: sheet.cells[row][col], allCells: sheet.cells)
        manager.updateSpreadsheet(sheet)
    }

    private func addRow() {
        let newRow = (0..<sheet.columns).map { _ in SpreadsheetCell() }
        sheet.cells.append(newRow)
        sheet.rows += 1
        manager.updateSpreadsheet(sheet)
    }

    private func addColumn() {
        for i in 0..<sheet.rows {
            sheet.cells[i].append(SpreadsheetCell())
        }
        sheet.columns += 1
        manager.updateSpreadsheet(sheet)
    }

    private func deleteRow(_ row: Int) {
        guard sheet.rows > 1, row < sheet.cells.count else { return }
        sheet.cells.remove(at: row)
        sheet.rows -= 1
        selectedCell = nil
        manager.updateSpreadsheet(sheet)
    }

    private func deleteColumn(_ col: Int) {
        guard sheet.columns > 1 else { return }
        for i in 0..<sheet.rows {
            if col < sheet.cells[i].count { sheet.cells[i].remove(at: col) }
        }
        sheet.columns -= 1
        selectedCell = nil
        manager.updateSpreadsheet(sheet)
    }

    private func columnLabel(_ col: Int) -> String {
        var result = ""
        var n = col + 1
        while n > 0 {
            let r = (n - 1) % 26
            result = String(UnicodeScalar(65 + r)!) + result
            n = (n - 1) / 26
        }
        return result
    }

    // MARK: - AI Sheet

    private var aiSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if aiLoading {
                    ProgressView("Analyzing…")
                } else if !aiResult.isEmpty {
                    ScrollView {
                        Text(aiResult)
                            .padding()
                    }
                } else {
                    Text("Choose an AI action")
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(spacing: 10) {
                    aiActionButton("Summarize Spreadsheet", icon: "text.alignleft") {
                        runAI("Summarize this spreadsheet data and provide key observations:\n\(buildDataString())")
                    }
                    aiActionButton("Analyze Trends", icon: "chart.line.uptrend.xyaxis") {
                        runAI("Analyze trends and patterns in this spreadsheet data:\n\(buildDataString())")
                    }
                    aiActionButton("Suggest Insights", icon: "lightbulb") {
                        runAI("Suggest insights and anomalies from this data:\n\(buildDataString())")
                    }
                    aiActionButton("Generate Formula", icon: "function") {
                        runAI("Suggest useful formulas for this spreadsheet (SUM, AVERAGE, etc.) based on:\n\(buildDataString())")
                    }
                }
                .padding()
            }
            .navigationTitle("AI Tools")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { showingAI = false }
                }
                if !aiResult.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Clear") { aiResult = "" }
                    }
                }
            }
        }
        .presentationDetents([.large])
    }

    private func aiActionButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private func runAI(_ prompt: String) {
        aiLoading = true
        aiResult = ""
        Task {
            do {
                let result = try await AIService.shared.processText(prompt: prompt)
                await MainActor.run { aiResult = result; aiLoading = false }
            } catch {
                await MainActor.run { aiResult = "Error: \(error.localizedDescription)"; aiLoading = false }
            }
        }
    }

    private func buildDataString() -> String {
        var lines: [String] = []
        for (r, row) in sheet.cells.prefix(50).enumerated() {
            let vals = row.map { $0.value.isEmpty ? "-" : $0.value }.joined(separator: ", ")
            lines.append("Row \(r+1): \(vals)")
        }
        return lines.joined(separator: "\n")
    }
}
