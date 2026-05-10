import SwiftUI

struct SpreadsheetEditorView: View {
    let spreadsheet: Spreadsheet
    @ObservedObject var manager: SpreadsheetsManager

    @State private var sheet: Spreadsheet
    @State private var selectedCell: (row: Int, col: Int)?
    @State private var showingCellEditor = false
    @State private var aiPrompt = ""
    @State private var aiResult: String?
    @State private var aiLoading = false

    private let colWidth: CGFloat = 100
    private let rowHeight: CGFloat = 36
    private let headerWidth: CGFloat = 44

    init(spreadsheet: Spreadsheet, manager: SpreadsheetsManager) {
        self.spreadsheet = spreadsheet
        self.manager = manager
        _sheet = State(initialValue: spreadsheet)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    FormulaBarView(selectedCell: selectedCell, sheet: sheet) { newFormula in
                        if let sel = selectedCell { updateCell(row: sel.row, col: sel.col, formula: newFormula) }
                    }
                    .padding()

                    Divider().opacity(0.1)

                    spreadsheetGrid

                    if let aiResult {
                        aiResultOverlay(aiResult)
                    }
                }
            }
            .navigationTitle(sheet.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { runAIAnalysis() } label: { Image(systemName: "sparkles") }
                    Button { addRow() } label: { Image(systemName: "plus.row.fill") }
                    Button { addColumn() } label: { Image(systemName: "plus.column.fill") }
                }
            }
        }
    }

    private var spreadsheetGrid: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    headerCell("")
                        .frame(width: headerWidth)
                    ForEach(0..<sheet.columns, id: \.self) { col in
                        headerCell(columnLabel(col))
                            .frame(width: colWidth)
                    }
                }

                ForEach(0..<sheet.rows, id: \.self) { row in
                    HStack(spacing: 0) {
                        headerCell("\(row + 1)")
                            .frame(width: headerWidth)

                        ForEach(0..<sheet.columns, id: \.self) { col in
                            dataCell(row: row, col: col)
                                .frame(width: colWidth)
                        }
                    }
                }
            }
        }
    }

    private func headerCell(_ text: String) -> some View {
        Text(text)
            .font(.caption.bold())
            .frame(height: rowHeight)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemBackground))
            .overlay(Rectangle().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
    }

    private func dataCell(row: Int, col: Int) -> some View {
        let isSelected = selectedCell?.row == row && selectedCell?.col == col
        let cell = sheet.cells[row][col]
        let display = manager.compute(cell: cell, allCells: sheet.cells)

        return Text(display)
            .font(.system(size: 13))
            .padding(.horizontal, 4)
            .frame(height: rowHeight, alignment: .leading)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.blue.opacity(0.2) : Color.clear)
            .overlay(Rectangle().stroke(isSelected ? Color.blue : Color.white.opacity(0.1), lineWidth: isSelected ? 1 : 0.5))
            .onTapGesture {
                selectedCell = (row, col)
            }
    }

    private func aiResultOverlay(_ result: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("AI Analysis", systemImage: "sparkles").font(.subheadline.bold())
                Spacer()
                Button { aiResult = nil } label: { Image(systemName: "xmark.circle.fill") }
            }
            Text(result).font(.caption)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding()
    }

    private func updateCell(row: Int, col: Int, formula: String) {
        sheet.cells[row][col].formula = formula
        manager.updateSpreadsheet(sheet)
    }

    private func addRow() {
        sheet.cells.append(Array(repeating: SpreadsheetCell(), count: sheet.columns))
        sheet.rows += 1
        manager.updateSpreadsheet(sheet)
    }

    private func addColumn() {
        for i in 0..<sheet.rows { sheet.cells[i].append(SpreadsheetCell()) }
        sheet.columns += 1
        manager.updateSpreadsheet(sheet)
    }

    private func runAIAnalysis() {
        aiLoading = true
        Task {
            do {
                let result = try await manager.analyzeSpreadsheet(prompt: "Analyze this sheet", dataPreview: "Data sample")
                await MainActor.run {
                    aiResult = result
                    aiLoading = false
                }
            } catch {
                aiLoading = false
            }
        }
    }

    private func columnLabel(_ col: Int) -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        return String(letters[letters.index(letters.startIndex, offsetBy: col % 26)])
    }
}
