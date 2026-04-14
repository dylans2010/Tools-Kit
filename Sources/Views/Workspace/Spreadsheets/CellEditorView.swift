import SwiftUI

struct CellEditorView: View {
    let cell: SpreadsheetCell
    let address: String
    let onSave: (String, String?) -> Void
    let onCancel: () -> Void

    @State private var rawValue: String
    @State private var formula: String
    @State private var isFormulaMode: Bool
    @State private var isBold: Bool
    @State private var isItalic: Bool
    @State private var alignment: SpreadsheetCell.CellAlignment
    @State private var numberFormat: SpreadsheetCell.CellNumberFormat

    init(cell: SpreadsheetCell, address: String, onSave: @escaping (String, String?) -> Void, onCancel: @escaping () -> Void) {
        self.cell = cell
        self.address = address
        self.onSave = onSave
        self.onCancel = onCancel
        _rawValue = State(initialValue: cell.value)
        _formula = State(initialValue: cell.formula ?? "")
        _isFormulaMode = State(initialValue: cell.formula != nil)
        _isBold = State(initialValue: cell.isBold)
        _isItalic = State(initialValue: cell.isItalic)
        _alignment = State(initialValue: cell.textAlignment)
        _numberFormat = State(initialValue: cell.numberFormat)
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

                Section("Formatting") {
                    Toggle("Bold", isOn: $isBold)
                    Toggle("Italic", isOn: $isItalic)

                    Picker("Alignment", selection: $alignment) {
                        Text("Left").tag(SpreadsheetCell.CellAlignment.leading)
                        Text("Center").tag(SpreadsheetCell.CellAlignment.center)
                        Text("Right").tag(SpreadsheetCell.CellAlignment.trailing)
                    }
                    .pickerStyle(.segmented)

                    Picker("Number Format", selection: $numberFormat) {
                        ForEach(SpreadsheetCell.CellNumberFormat.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
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
        .presentationDetents([.large])
    }
}
