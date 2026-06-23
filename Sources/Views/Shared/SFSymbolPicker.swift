import SwiftUI

struct SFSymbolPicker: View {
    @Binding var selectedIcon: String

    var body: some View {
        List {
            Text("SFSymbolPicker Placeholder")
            Text("Selected Icon: \(selectedIcon)")
        }
        .navigationTitle("Select Icon")
    }
}
