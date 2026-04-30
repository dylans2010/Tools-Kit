import SwiftUI

struct DatabaseBlockView: View {
    @Binding var block: NotebookBlock
    var onUpdate: () -> Void

    @ObservedObject var db = NotebookDatabaseEngine.shared
    @State private var tableID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let id = tableID {
                NotebookTableView(tableID: id)
            } else {
                Button("Initialize Database") {
                    let newID = UUID()
                    db.tables[newID] = []
                    db.schemas[newID] = .init(columns: [.init(id: UUID(), name: "Column 1", type: .text)])
                    tableID = newID
                    block.metadata["tableID"] = newID.uuidString
                    onUpdate()
                }
                .buttonStyle(.bordered)
            }
        }
        .onAppear {
            if let idString = block.metadata["tableID"], let id = UUID(uuidString: idString) {
                tableID = id
            }
        }
    }
}
