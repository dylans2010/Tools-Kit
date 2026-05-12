import SwiftUI

struct CollabWhiteboardView: View {
    @State private var canvasItems: [WhiteboardCanvasItem] = []
    @State private var selectedTool: WhiteboardTool = .select
    @State private var selectedColor: Color = .blue
    @State private var showingToolbar = true

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                if showingToolbar {
                    toolbarView
                }

                ZStack {
                    ForEach(canvasItems) { item in
                        canvasItemView(item)
                    }

                    if canvasItems.isEmpty {
                        ContentUnavailableView("Empty Canvas", systemImage: "scribble.variable", description: Text("Start by adding shapes, text, or sticky notes."))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                bottomBar
            }
        }
        .navigationTitle("Whiteboard")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingToolbar.toggle()
                } label: {
                    Image(systemName: showingToolbar ? "paintbrush.fill" : "paintbrush")
                }
            }
        }
    }

    private var toolbarView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(WhiteboardTool.allCases, id: \.self) { tool in
                    Button {
                        selectedTool = tool
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: tool.icon)
                                .font(.title3)
                            Text(tool.rawValue)
                                .font(.caption2)
                        }
                        .frame(width: 56, height: 48)
                        .background(selectedTool == tool ? Color.blue.opacity(0.2) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .foregroundStyle(selectedTool == tool ? .blue : .primary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }

    private var bottomBar: some View {
        HStack {
            HStack(spacing: 8) {
                ForEach([Color.blue, .red, .green, .orange, .purple, .black], id: \.self) { color in
                    Circle()
                        .fill(color)
                        .frame(width: 24, height: 24)
                        .overlay(Circle().stroke(selectedColor == color ? Color.white : Color.clear, lineWidth: 2))
                        .onTapGesture { selectedColor = color }
                }
            }
            Spacer()
            Button {
                addItem()
            } label: {
                Label("Add", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.bordered)
            Button(role: .destructive) {
                canvasItems.removeAll()
            } label: {
                Label("Clear", systemImage: "trash")
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(.systemBackground))
    }

    private func canvasItemView(_ item: WhiteboardCanvasItem) -> some View {
        VStack {
            if item.type == .stickyNote {
                VStack {
                    Text(item.text)
                        .font(.caption)
                        .padding(8)
                }
                .frame(width: 120, height: 100)
                .background(item.color.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 4))
            } else if item.type == .text {
                Text(item.text)
                    .font(.subheadline)
                    .foregroundStyle(item.color)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(item.color, lineWidth: 2)
                    .frame(width: 80, height: 60)
            }
        }
        .offset(x: item.x, y: item.y)
    }

    private func addItem() {
        let item = WhiteboardCanvasItem(
            type: selectedTool == .stickyNote ? .stickyNote : selectedTool == .text ? .text : .shape,
            text: selectedTool == .stickyNote ? "Note" : selectedTool == .text ? "Text" : "",
            color: selectedColor,
            x: CGFloat.random(in: -100...100),
            y: CGFloat.random(in: -100...100)
        )
        canvasItems.append(item)
    }
}

private struct WhiteboardCanvasItem: Identifiable, Sendable {
    let id = UUID()
    let type: CanvasItemType
    let text: String
    let color: Color
    let x: CGFloat
    let y: CGFloat
}

private enum CanvasItemType: Sendable { case stickyNote, text, shape }

private enum WhiteboardTool: String, CaseIterable, Sendable {
    case select, pen, shape, text, stickyNote = "sticky", eraser

    var icon: String {
        switch self {
        case .select: return "cursorarrow"
        case .pen: return "pencil.tip"
        case .shape: return "rectangle"
        case .text: return "textformat"
        case .stickyNote: return "note.text"
        case .eraser: return "eraser"
        }
    }
}
