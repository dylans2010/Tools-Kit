import SwiftUI

struct SDKDataControlView: View {
    @State private var collection = "notebook_pages"
    @State private var itemCount = 0

    var body: some View {
        VStack {
            List {
                Section(header: Text("Data Inspector")) {
                    TextField("Collection", text: $collection)
                    Button("Refresh Count") {
                        // Logic to fetch all and count
                        if let items = try? WorkspaceSDK.shared.storage.fetchAll(in: collection) as [SDKNotebooks.Page] {
                            itemCount = items.count
                        } else if let items = try? WorkspaceSDK.shared.storage.fetchAll(in: collection) as [SDKMail.Message] {
                            itemCount = items.count
                        } else {
                            itemCount = 0
                        }
                    }
                    HStack {
                        Text("Item Count")
                        Spacer()
                        Text("\(itemCount)")
                    }
                }
            }
        }
        .navigationTitle("Data Inspector")
    }
}
