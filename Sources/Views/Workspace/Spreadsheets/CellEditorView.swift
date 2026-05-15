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
            ZStack {
                Color(uiColor: .systemBackground).ignoresSafeArea()

                Form {
                    Section {
                        Toggle("Formula Mode", isOn: $isFormulaMode)
                    }
                    .listRowBackground(Color(uiColor: .secondarySystemBackground))

                    if isFormulaMode {
                        Section {
                            TextField("=SUM(A1:A10)", text: $formula)
                                .font(.system(.body, design: .monospaced))
                        } header: {
                            Text("Formula")
                        }
                        .listRowBackground(Color(uiColor: .secondarySystemBackground))
                    } else {
                        Section {
                            TextField("Cell value", text: $rawValue)
                        } header: {
                            Text("Value")
                        }
                        .listRowBackground(Color(uiColor: .secondarySystemBackground))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Cell \(address)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(isFormulaMode ? "" : rawValue, isFormulaMode ? formula : nil)
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
}
