import SwiftUI
import SymbolPicker

struct SFSymbolPicker: View {
    @State private var iconPickerPresented = false
    @State private var icon = "pencil"

    var body: some View {
        Button {
            iconPickerPresented = true
        } label: {
            HStack {
                Image(systemName: icon)
                Text(icon)
            }
        }
        .sheet(isPresented: $iconPickerPresented) {
            SymbolPicker(symbol: $icon)
        }
    }
}
