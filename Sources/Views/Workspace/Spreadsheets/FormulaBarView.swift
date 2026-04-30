import SwiftUI

struct FormulaBarView: View {
    let selectedCell: (row: Int, col: Int)?
    let sheet: Spreadsheet
    let onFormulaChanged: (String) -> Void

    @State private var editingFormula = ""

    private var address: String {
        guard let sel = selectedCell else { return "" }
        return "\(columnLabel(sel.col))\(sel.row + 1)"
    }

    private var currentFormula: String {
        guard let sel = selectedCell, sel.row < sheet.cells.count, sel.col < sheet.cells[sel.row].count else { return "" }
        let cell = sheet.cells[sel.row][sel.col]
        return cell.formula ?? cell.value
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(address.isEmpty ? "—" : address)
                .font(.system(.subheadline, design: .monospaced).bold())
                .foregroundStyle(.blue)
                .frame(width: 50)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

            Image(systemName: "function")
                .foregroundStyle(.secondary)

            TextField("Enter value or formula", text: $editingFormula)
                .font(.system(.body, design: .monospaced))
                .onSubmit { onFormulaChanged(editingFormula) }
                .onChange(of: selectedCell?.row) { editingFormula = currentFormula }
                .onChange(of: selectedCell?.col) { editingFormula = currentFormula }
        }
        .padding(10)
        .background(Color.workspaceSurface, in: RoundedRectangle(cornerRadius: 12))
        .onAppear { editingFormula = currentFormula }
    }

    private func columnLabel(_ col: Int) -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        return String(letters[letters.index(letters.startIndex, offsetBy: col % 26)])
    }
}
