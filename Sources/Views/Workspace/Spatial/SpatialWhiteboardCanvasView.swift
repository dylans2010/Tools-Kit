import SwiftUI

struct SpatialWhiteboardCanvasView: View {
    @StateObject private var engine: CanvasEngine
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero

    init(canvas: SpatialCanvas) {
        _engine = StateObject(wrappedValue: CanvasEngine(canvas: canvas))
    }

    var body: some View {
        ZStack {
            // Infinite Grid Background
            InfiniteGridView()
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            offset = CGSize(width: offset.width + value.translation.width, height: offset.height + value.translation.height)
                        }
                )

            // Elements
            ForEach(engine.canvas.layers.flatMap(\.elements)) { element in
                SpatialElementView(element: element)
                    .position(x: element.position.x + offset.width, y: element.position.y + offset.height)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newPos = CGPoint(
                                    x: element.position.x + value.translation.width,
                                    y: element.position.y + value.translation.height
                                )
                                engine.updateElementPosition(element.id, to: newPos)
                            }
                    )
            }

            VStack {
                Spacer()
                ToolbarView(engine: engine)
                    .padding()
            }
        }
        .navigationTitle(engine.canvas.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct InfiniteGridView: View {
    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 50
            for x in stride(from: 0, through: size.width, by: step) {
                context.stroke(Path { p in
                    p.move(to: CGPoint(x: x, y: 0))
                    p.addLine(to: CGPoint(x: x, y: size.height))
                }, with: .color(.gray.opacity(0.2)))
            }
            for y in stride(from: 0, through: size.height, by: step) {
                context.stroke(Path { p in
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: size.width, y: y))
                }, with: .color(.gray.opacity(0.2)))
            }
        }
        .background(Color(uiColor: .systemBackground))
    }
}

struct SpatialElementView: View {
    let element: SpatialElement

    var body: some View {
        VStack {
            if element.type == .stickyNote {
                Text(element.properties["text"] ?? "")
                    .padding()
                    .frame(width: element.size.width, height: element.size.height)
                    .background(Color.yellow.opacity(0.8))
                    .cornerRadius(8)
                    .shadow(radius: 4)
            }
        }
    }
}

struct ToolbarView: View {
    @ObservedObject var engine: CanvasEngine

    var body: some View {
        HStack(spacing: 20) {
            Button(action: { engine.addElement(.stickyNote, at: CGPoint(x: 100, y: 100)) }) {
                Image(systemName: "plus.square.fill")
                    .font(.title)
            }

            Button(action: {}) {
                Image(systemName: "pencil.tip.crop.circle")
                    .font(.title)
            }

            Button(action: {}) {
                Image(systemName: "photo")
                    .font(.title)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(Capsule())
        .shadow(radius: 10)
    }
}
