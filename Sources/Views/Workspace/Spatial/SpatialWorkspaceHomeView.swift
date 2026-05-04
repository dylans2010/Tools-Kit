import SwiftUI

struct SpatialWorkspaceHomeView: View {
    @StateObject private var manager = SpatialCanvasManager.shared
    @State private var zoomScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero

    var body: some View {
        ZStack {
            // Infinite Grid Background
            InfiniteGridView()
                .scaleEffect(zoomScale)
                .offset(offset)

            // Canvas Items
            ForEach(manager.currentCanvas.items) { item in
                CanvasItemView(item: item)
                    .position(x: item.position.x * zoomScale + offset.width,
                              y: item.position.y * zoomScale + offset.height)
            }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    offset = CGSize(width: value.translation.width, height: value.translation.height)
                }
        )
        .overlay(alignment: .bottomTrailing) {
            controls
        }
        .navigationTitle("Spatial Workspace")
        .background(Color(.systemBackground))
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Button(action: { manager.addItem(.note, at: .zero) }) {
                Image(systemName: "plus.square.fill")
                    .font(.title)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }

            HStack {
                Button(action: { zoomScale *= 1.1 }) {
                    Image(systemName: "plus.magnifyingglass")
                }
                Button(action: { zoomScale /= 1.1 }) {
                    Image(systemName: "minus.magnifyingglass")
                }
            }
            .padding(8)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .padding(24)
    }
}

struct InfiniteGridView: View {
    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 50
            for x in stride(from: 0, through: size.width, by: step) {
                context.stroke(Path(CGRect(x: x, y: 0, width: 1, height: size.height)), with: .color(.gray.opacity(0.2)))
            }
            for y in stride(from: 0, through: size.height, by: step) {
                context.stroke(Path(CGRect(x: 0, y: y, width: size.width, height: 1)), with: .color(.gray.opacity(0.2)))
            }
        }
        .ignoresSafeArea()
    }
}

struct CanvasItemView: View {
    let item: CanvasItem

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: iconForType(item.type))
                Text(item.type.rawValue.capitalized)
                    .font(.caption.bold())
            }
            .foregroundColor(.white)
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(colorForType(item.type))

            Text(item.content)
                .font(.caption)
                .padding(8)

            Spacer()
        }
        .frame(width: 150, height: 150)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(radius: 4)
    }

    private func iconForType(_ t: CanvasItem.ItemType) -> String {
        switch t {
        case .note: return "note.text"
        case .image: return "photo"
        case .task: return "checklist"
        case .file: return "doc.fill"
        case .whiteboard: return "pencil.and.outline"
        }
    }

    private func colorForType(_ t: CanvasItem.ItemType) -> Color {
        switch t {
        case .note: return .orange
        case .image: return .blue
        case .task: return .green
        case .file: return .purple
        case .whiteboard: return .teal
        }
    }
}
