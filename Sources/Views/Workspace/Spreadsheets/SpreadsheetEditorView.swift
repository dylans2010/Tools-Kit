import SwiftUI

struct SpreadsheetEditorView: View {
    let spreadsheet: Spreadsheet
    @ObservedObject var manager: SpreadsheetsManager

    @State private var sheet: Spreadsheet
    @State private var selectedCell: (row: Int, col: Int)?
    @State private var showingCellEditor = false
    @State private var aiPrompt = "Analyze selected range"
    @State private var aiResult: SpreadsheetsManager.SpreadsheetAIPayload?
    @State private var aiError: String?
    @State private var aiLoading = false

    private let colWidth: CGFloat = 120
    private let rowHeight: CGFloat = 40
    private let headerWidth: CGFloat = 52
    private let maxAIPreviewRows = 50

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
                    guard let selectedCell else { return }
                    updateCell(row: selectedCell.row, col: selectedCell.col, formula: newFormula)
                }
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            SpreadsheetToolbarView(
                onAddRow: addRow,
                onAddColumn: addColumn,
                onDeleteRow: { if let selectedCell { deleteRow(selectedCell.row) } },
                onDeleteColumn: { if let selectedCell { deleteColumn(selectedCell.col) } },
                onBold: toggleBold,
                onItalic: toggleItalic,
                onAlignLeft: { setAlignment(.leading) },
                onAlignCenter: { setAlignment(.center) },
                onAlignRight: { setAlignment(.trailing) },
                onFormatNumber: { setFormat(.number) },
                onFormatCurrency: { setFormat(.currency) },
                onFormatPercentage: { setFormat(.percentage) },
                onFormatDate: { setFormat(.date) },
                onSum: fillSum,
                onAverage: fillAverage,
                onClearCell: clearCell,
                onAI: runAIAnalysis
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            Divider()

            HStack(spacing: 0) {
                gridPanel
                Divider()
                aiPanel
                    .frame(width: 320)
            }
        }
        .navigationTitle(sheet.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingCellEditor) {
            if let selectedCell {
                CellEditorView(
                    cell: sheet.cells[selectedCell.row][selectedCell.col],
                    address: "\(columnLabel(selectedCell.col))\(selectedCell.row + 1)",
                    onSave: { value, formula in
                        updateCell(row: selectedCell.row, col: selectedCell.col, value: value, formula: formula)
                        showingCellEditor = false
                    },
                    onCancel: { showingCellEditor = false }
                )
            }
        }
    }

    private var gridPanel: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color(.systemGray6))
                        .frame(width: headerWidth, height: rowHeight)
                    ForEach(0..<sheet.columns, id: \.self) { col in
                        Text(columnLabel(col))
                            .font(.caption.weight(.bold))
                            .frame(width: colWidth, height: rowHeight)
                            .background(Color(.systemGray6))
                            .overlay(Rectangle().stroke(Color(.systemGray4), lineWidth: 0.5))
                    }
                }
                ForEach(0..<sheet.rows, id: \.self) { row in
                    HStack(spacing: 0) {
                        Text("\(row + 1)")
                            .font(.caption)
                            .frame(width: headerWidth, height: rowHeight)
                            .background(Color(.systemGray6))
                            .overlay(Rectangle().stroke(Color(.systemGray4), lineWidth: 0.5))
                        ForEach(0..<sheet.columns, id: \.self) { col in
                            cellView(row: row, col: col)
                        }
                    }
                }
            }
        }
    }

    private var aiPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("AI Insights")
                    .font(.headline)
                TextField("e.g. detect trends and generate formulas", text: $aiPrompt)
                    .textFieldStyle(.roundedBorder)
                Button("Analyze", action: runAIAnalysis)
                    .buttonStyle(.borderedProminent)
                    .disabled(aiLoading)

                if aiLoading {
                    WorkspaceSkeletonLine()
                    WorkspaceSkeletonLine(widthRatio: 0.7)
                    WorkspaceSkeletonLine(widthRatio: 0.5)
                } else if let aiError {
                    Text(aiError)
                        .font(.caption)
                        .foregroundStyle(.red)
                } else if let aiResult {
                    insightSection("Summary", [aiResult.summary])
                    insightSection("Formula Suggestions", aiResult.formulaSuggestions)
                    insightSection("Column Types", aiResult.columnTypes)
                    insightSection("Range Insights", aiResult.rangeInsights)
                    insightSection("Chart Suggestions", aiResult.chartSuggestions)
                } else {
                    Text("Run AI to generate formulas, infer column types, and summarize selected ranges.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
        }
        .background(Color(.systemBackground))
    }

    private func insightSection(_ title: String, _ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            ForEach(items, id: \.self) { item in
                Text("• \(item)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
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
            .padding(.horizontal, 8)
            .background(isSelected ? Color.accentColor.opacity(0.15) : Color(.systemBackground))
            .overlay(
                Rectangle()
                    .stroke(isSelected ? Color.accentColor : Color(.systemGray4), lineWidth: isSelected ? 1.8 : 0.5)
            )
            .onTapGesture {
                selectedCell = (row, col)
                showingCellEditor = true
            }
    }

    // MARK: - Editing Helpers

    private func updateCell(row: Int, col: Int, value: String? = nil, formula: String? = nil) {
        guard row < sheet.cells.count, col < sheet.cells[row].count else { return }
        if let value { sheet.cells[row][col].value = value }
        sheet.cells[row][col].formula = formula?.isEmpty == false ? formula : nil
        sheet.cells[row][col].computedValue = manager.compute(cell: sheet.cells[row][col], allCells: sheet.cells)
        manager.updateSpreadsheet(sheet)
    }

    private func addRow() {
        sheet.cells.append((0..<sheet.columns).map { _ in SpreadsheetCell() })
        sheet.rows += 1
        manager.updateSpreadsheet(sheet)
    }

    private func addColumn() {
        for row in 0..<sheet.rows { sheet.cells[row].append(SpreadsheetCell()) }
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
        for row in 0..<sheet.rows where col < sheet.cells[row].count {
            sheet.cells[row].remove(at: col)
        }
        sheet.columns -= 1
        selectedCell = nil
        manager.updateSpreadsheet(sheet)
    }

    private func toggleBold() {
        guard let selectedCell else { return }
        sheet.cells[selectedCell.row][selectedCell.col].isBold.toggle()
        manager.updateSpreadsheet(sheet)
    }

    private func toggleItalic() {
        guard let selectedCell else { return }
        sheet.cells[selectedCell.row][selectedCell.col].isItalic.toggle()
        manager.updateSpreadsheet(sheet)
    }

    private func setAlignment(_ alignment: SpreadsheetCell.CellAlignment) {
        guard let selectedCell else { return }
        sheet.cells[selectedCell.row][selectedCell.col].textAlignment = alignment
        manager.updateSpreadsheet(sheet)
    }

    private func setFormat(_ format: SpreadsheetCell.CellNumberFormat) {
        guard let selectedCell else { return }
        sheet.cells[selectedCell.row][selectedCell.col].numberFormat = format
        manager.updateSpreadsheet(sheet)
    }

    private func fillSum() {
        guard let selectedCell else { return }
        let values = (0..<selectedCell.row).compactMap { Double(sheet.cells[$0][selectedCell.col].value) }
        sheet.cells[selectedCell.row][selectedCell.col].value = String(values.reduce(0, +))
        manager.updateSpreadsheet(sheet)
    }

    private func fillAverage() {
        guard let selectedCell else { return }
        let values = (0..<selectedCell.row).compactMap { Double(sheet.cells[$0][selectedCell.col].value) }
        let average = values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
        sheet.cells[selectedCell.row][selectedCell.col].value = String(format: "%.2f", average)
        manager.updateSpreadsheet(sheet)
    }

    private func clearCell() {
        guard let selectedCell else { return }
        sheet.cells[selectedCell.row][selectedCell.col].value = ""
        sheet.cells[selectedCell.row][selectedCell.col].formula = nil
        sheet.cells[selectedCell.row][selectedCell.col].computedValue = ""
        manager.updateSpreadsheet(sheet)
    }

    private func runAIAnalysis() {
        aiLoading = true
        aiError = nil
        aiResult = nil
        Task {
            do {
                // AI receives a compact CSV-like preview and returns schema-validated insights.
                let result = try await manager.analyzeSpreadsheet(
                    prompt: aiPrompt,
                    dataPreview: buildDataString()
                )
                await MainActor.run {
                    aiResult = result
                    aiLoading = false
                }
            } catch {
                await MainActor.run {
                    aiError = "AI response could not be validated. Please retry with a clearer prompt."
                    aiLoading = false
                }
            }
        }
    }

    private func buildDataString() -> String {
        sheet.cells.prefix(maxAIPreviewRows).enumerated().map { rowIndex, values in
            "Row \(rowIndex + 1): \(values.map { $0.value.isEmpty ? "-" : $0.value }.joined(separator: ", "))"
        }.joined(separator: "\n")
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
}
