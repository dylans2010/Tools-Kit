import SwiftUI

struct CellEditorView: View {
    let cell: SpreadsheetCell
    let address: String
    let onSave: (String, String?) -> Void
    let onCancel: () -> Void

    @State private var rawValue: String
    @State private var formula: String
    @State private var isFormulaMode: Bool

    init(cell: SpreadsheetCell, address: String, onSave: @escaping (String, String?) -> Void, onCancel: @escaping () -> Void) {
        self.cell = cell
        self.address = address
        self.onSave = onSave
        self.onCancel = onCancel
        _rawValue = State(initialValue: cell.value)
        _formula = State(initialValue: cell.formula ?? "")
        _isFormulaMode = State(initialValue: cell.formula != nil)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Formula Mode", isOn: $isFormulaMode)
                }

                if isFormulaMode {
                    Section("Formula (e.g. =SUM(A1:A5))") {
                        TextField("=SUM(A1:A5)", text: $formula)
                            .font(.system(.body, design: .monospaced))
                            .autocapitalization(.allCharacters)
                            .autocorrectionDisabled()
                    }
                } else {
                    Section("Value") {
                        TextField("Enter value", text: $rawValue)
                    }
                }
            }
            .navigationTitle("Cell \(address)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if isFormulaMode {
                            onSave("", formula.isEmpty ? nil : formula)
                        } else {
                            onSave(rawValue, nil)
                        }
                    }
                    .bold()
                }
            }
        }
        .presentationDetents([.medium])
    }
}
