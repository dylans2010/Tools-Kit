import SwiftUI

struct SFSymbolPicker: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var symbol: String

    var body: some View {
        NavigationStack {
            SymbolPicker(symbol: $symbol)
                .navigationTitle("Select Icon")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}
