import SwiftUI

struct GroceryListView: View {
    let items: [String]

    var body: some View {
        List {
            if items.isEmpty {
                Text("No groceries yet.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(items, id: \.self) { item in
                    Label(item.capitalized, systemImage: "cart")
                }
            }
        }
        .navigationTitle("Grocery List")
    }
}
