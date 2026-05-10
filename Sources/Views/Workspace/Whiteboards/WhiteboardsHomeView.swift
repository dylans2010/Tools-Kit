import SwiftUI

struct WhiteboardsHomeView: View {
    @StateObject private var store = WhiteboardStore.shared
    @State private var showingCreate = false
    @State private var boardName = ""

    var body: some View {
        List {
            Section("Whiteboards") {
                ForEach(store.boards) { board in
                    NavigationLink {
                        WhiteboardCanvasView(board: board)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(board.title)
                                .font(.headline)
                            Text("\(board.nodes.count) nodes • \(board.edges.count) edges")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Whiteboards")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingCreate = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("New Whiteboard", isPresented: $showingCreate) {
            TextField("Board name", text: $boardName)
            Button("Cancel", role: .cancel) {}
            Button("Create") {
                let name = boardName.trimmingCharacters(in: .whitespacesAndNewlines)
                store.createBoard(named: name.isEmpty ? "Untitled Board" : name)
                boardName = ""
            }
        }
    }
}
