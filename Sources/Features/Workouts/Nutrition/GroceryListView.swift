import SwiftUI

struct GroceryListView: View {
    @State private var items: [String]
    @State private var customItem = ""

    init(items: [String]) {
        _items = State(initialValue: items)
    }

    var body: some View {
        List {
            Section("Items") {
                if items.isEmpty {
                    Text("No groceries yet.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(items, id: \.self) { item in
                        Label(item.capitalized, systemImage: "cart")
                    }
                    .onDelete { indexSet in
                        items.remove(atOffsets: indexSet)
                    }
                }
            }

            Section("Add Custom") {
                TextField("Custom grocery item", text: $customItem)
                Button {
                    let trimmed = customItem.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    items.append(trimmed)
                    customItem = ""
                } label: {
                    Label("Add", systemImage: "plus.circle.fill")
                }
            }
        }
        .navigationTitle("Grocery List")
        .toolbar { EditButton() }
    }
}
