import SwiftUI

struct FullEditorView: View {
    let projectID: UUID
    @StateObject private var manager = EditingManager.shared
    @Environment(\.dismiss) var dismiss

    private var project: EditingProject? {
        manager.projects.first { $0.id == projectID }
    }

    var body: some View {
        Group {
            if let project = project {
                ZStack {
                    EditingEngineRepresentable(project: project)
                        .edgesIgnoringSafeArea(.all)

                    VStack {
                        headerView(project: project)
                        Spacer()
                        toolPalette
                        layerPanel
                    }
                }
            } else {
                Text("Project not found")
            }
        }
        .navigationBarHidden(true)
    }

    private func headerView(project: EditingProject) -> some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .padding()
                    .background(Circle().fill(Color.black.opacity(0.5)))
            }
            Spacer()
            Text(project.name)
                .font(.headline)
                .shadow(radius: 2)
            Spacer()
            Button("Export") {
                Task {
                    do {
                        let url = try await EditingFramework.shared.exportProject(projectID: projectID)
                        print("Exported to: \(url)")
                    } catch {
                        print("Export failed: \(error)")
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.blue)
            .cornerRadius(8)
        }
        .foregroundColor(.white)
        .padding()
    }

    private var toolPalette: some View {
        HStack(spacing: 20) {
            toolButton(icon: "arrow.uturn.backward", name: "Undo") {
                manager.undo(projectID: projectID)
            }
            toolButton(icon: "arrow.uturn.forward", name: "Redo") {
                manager.redo(projectID: projectID)
            }
            toolButton(icon: "paintbrush", name: "Brush") {}
            toolButton(icon: "textformat", name: "Text") {}
            toolButton(icon: "slider.horizontal.3", name: "Adjust") {}
        }
        .padding()
        .background(EditorBlurView(style: .systemThinMaterialDark))
        .cornerRadius(20)
        .padding(.bottom)
    }

    private var layerPanel: some View {
        // Horizontal mini-layer preview
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                if let project = project {
                    ForEach(project.layers) { layer in
                        VStack {
                            Image(systemName: iconFor(layer.type))
                            Text(layer.name).font(.caption2)
                        }
                        .frame(width: 60, height: 60)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(8)
                    }
                }
            }
            .padding()
        }
        .background(Color.black.opacity(0.5))
    }

    private func toolButton(icon: String, name: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                Text(name)
                    .font(.caption2)
            }
            .foregroundColor(.white)
        }
    }

    private func iconFor(_ type: LayerType) -> String {
        switch type {
        case .image: return "photo"
        case .video: return "video"
        case .text: return "textformat"
        case .shape: return "square"
        case .brush: return "paintbrush"
        }
    }
}

#if os(iOS)
struct EditingEngineRepresentable: UIViewRepresentable {
    let project: EditingProject

    func makeUIView(context: Context) -> EditingEngine {
        EditingEngine(project: project)
    }

    func updateUIView(_ uiView: EditingEngine, context: Context) {
        uiView.updateProject(project)
    }
}

struct EditorBlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
#else
struct EditingEngineRepresentable: View {
    let project: EditingProject
    var body: some View {
        EditingEngine()
    }
}
struct EditorBlurView: View {
    enum Style { case systemThinMaterialDark }
    let style: Style
    var body: some View {
        Color.black.opacity(0.5)
    }
}
#endif
