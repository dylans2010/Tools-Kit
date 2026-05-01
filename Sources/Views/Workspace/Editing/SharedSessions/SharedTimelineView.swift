import SwiftUI

struct SharedTimelineView: View {
    @StateObject private var manager = SharedEditingManager.shared
    let project: EditingProject

    var body: some View {
        VStack(spacing: 0) {
            // Active Editors Header
            HStack {
                Text("Collaborators").font(.caption.bold())
                Spacer()
                HStack(spacing: -8) {
                    ForEach(manager.activeUsers) { user in
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 24, height: 24)
                            .overlay(Text(user.name.prefix(1)).font(.system(size: 10)).foregroundColor(.white))
                            .overlay(Circle().stroke(Color.white, lineWidth: 1))
                    }
                }
            }
            .padding()
            .background(Color.workspaceSurface)

            // Timeline Surface
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(project.layers) { layer in
                        LayerTrackView(layer: layer, isBeingEdited: manager.activeUsers.contains(where: { $0.activeLayerID == layer.id }))
                    }
                }
                .padding()
            }
        }
    }
}

struct LayerTrackView: View {
    let layer: EditingLayer
    let isBeingEdited: Bool

    var body: some View {
        HStack {
            Image(systemName: iconName(for: layer.type))
            Text(layer.name)
            Spacer()
            if isBeingEdited {
                Image(systemName: "pencil")
                    .foregroundColor(.orange)
                    .transition(.scale)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isBeingEdited ? Color.orange : Color.clear, lineWidth: 2)
        )
    }

    private func iconName(for type: LayerType) -> String {
        switch type {
        case .image: return "photo"
        case .video: return "video"
        case .text: return "textformat"
        case .shape: return "square.on.circle"
        case .brush: return "paintbrush"
        }
    }
}
