import SwiftUI

struct WhiteboardCanvasView: View {
    @State private var board: WhiteboardBoard
    @State private var showingAddNode = false
    @State private var nodeTitle = ""
    @State private var nodeContent = ""

    init(board: WhiteboardBoard) {
        _board = State(initialValue: board)
    }

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            ZStack(alignment: .topLeading) {
                ForEach(board.nodes) { node in
                    WhiteboardNodeView(node: node)
                        .position(x: node.positionX, y: node.positionY)
                }
            }
            .frame(minWidth: 900, minHeight: 600)
        }
        .navigationTitle(board.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddNode = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddNode) {
            NavigationStack {
                Form {
                    TextField("Node title", text: $nodeTitle)
                    TextField("Node content", text: $nodeContent, axis: .vertical)
                        .lineLimit(3...6)
                }
                .navigationTitle("New Node")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingAddNode = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            addNode()
                            showingAddNode = false
                        }
                        .disabled(nodeTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
        .onDisappear {
            WhiteboardStore.shared.updateBoard(board)
        }
    }

    private func addNode() {
        let base = Double(board.nodes.count + 1)
        board.nodes.append(
            WhiteboardNode(
                title: nodeTitle,
                content: nodeContent,
                type: .concept,
                positionX: 120 + (base * 80).truncatingRemainder(dividingBy: 600),
                positionY: 120 + (base * 60).truncatingRemainder(dividingBy: 400)
            )
        )
        nodeTitle = ""
        nodeContent = ""
    }
}
