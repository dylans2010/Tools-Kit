import SwiftUI

struct FormulaBarView: View {
    let selectedCell: (row: Int, col: Int)?
    let sheet: Spreadsheet
    let onFormulaChanged: (String) -> Void

    @State private var editingFormula = ""
    @State private var isEditing = false

    private var address: String {
        guard let sel = selectedCell else { return "" }
        return "\(columnLabel(sel.col))\(sel.row + 1)"
    }

    private var currentFormula: String {
        guard let sel = selectedCell,
              sel.row < sheet.cells.count,
              sel.col < sheet.cells[sel.row].count else { return "" }
        let cell = sheet.cells[sel.row][sel.col]
        return cell.formula ?? cell.value
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(address.isEmpty ? "—" : address)
                .font(.system(.footnote, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 48, alignment: .center)
                .padding(.horizontal, 4)
                .background(Color(.systemGray6))
                .cornerRadius(6)

            Divider().frame(height: 22)

            TextField("Value or formula", text: $editingFormula, onCommit: {
                onFormulaChanged(editingFormula)
                isEditing = false
            })
            .font(.system(.body, design: .monospaced))
            .autocorrectionDisabled()
            .autocapitalization(.allCharacters)
            .onAppear { editingFormula = currentFormula }
            .onChange(of: selectedCell?.row) { _ in editingFormula = currentFormula }
            .onChange(of: selectedCell?.col) { _ in editingFormula = currentFormula }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .overlay(Divider(), alignment: .bottom)
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
