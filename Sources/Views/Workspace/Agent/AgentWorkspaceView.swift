import SwiftUI

struct AgentWorkspaceView: View {
    @ObservedObject var state: AgentSessionState
    @State private var expandedNodes: Set<String> = []

    var body: some View {
        VStack(spacing: 0) {
            // Quick Access Bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    QuickAccessButton(title: "Timeline", icon: "clock.fill", color: .blue) { state.selectedTab = 1 }
                    QuickAccessButton(title: "Tools", icon: "hammer.fill", color: .orange) { state.selectedTab = 2 }
                    QuickAccessButton(title: "Memory", icon: "brain.fill", color: .purple) { state.selectedTab = 3 }
                    QuickAccessButton(title: "Checkpoints", icon: "clock.arrow.circlepath", color: .green) { state.selectedTab = 5 }
                    QuickAccessButton(title: "Diffs", icon: "doc.text.magnifyingglass", color: .red) { state.selectedTab = 4 }
                }
                .padding()
            }
            .background(Color(uiColor: .secondarySystemBackground))

            Divider()

            // File Tree
            List {
                if state.workspaceFiles.isEmpty {
                    ContentUnavailableView(
                        "No Workspace Files",
                        systemImage: "folder",
                        description: Text("Wait for the agent to initialize the workspace.")
                    )
                } else {
                    let root = buildTree(from: state.workspaceFiles)
                    ForEach(root.children) { node in
                        FileTreeNodeView(node: node, expandedNodes: $expandedNodes, level: 0)
                    }
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("Agent Workspace")
    }

    private func buildTree(from files: [String]) -> FileNode {
        let root = FileNode(name: "root", path: "", isDirectory: true)
        for file in files {
            let components = file.components(separatedBy: "/")
            var currentNode = root
            var currentPath = ""
            for (index, component) in components.enumerated() {
                if component.isEmpty { continue }
                currentPath = currentPath.isEmpty ? component : "\(currentPath)/\(component)"
                let isDirectory = index < components.count - 1

                if let existing = currentNode.children.first(where: { $0.name == component }) {
                    currentNode = existing
                } else {
                    let newNode = FileNode(name: component, path: currentPath, isDirectory: isDirectory)
                    currentNode.children.append(newNode)
                    currentNode.children.sort { ($0.isDirectory ? 0 : 1, $0.name) < ($1.isDirectory ? 0 : 1, $1.name) }
                    currentNode = newNode
                }
            }
        }
        return root
    }
}

struct QuickAccessButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption2.bold())
                    .foregroundColor(.primary)
            }
            .frame(width: 70, height: 60)
            .background(Color(uiColor: .systemBackground))
            .cornerRadius(8)
            .shadow(radius: 1)
        }
        .buttonStyle(.plain)
    }
}

class FileNode: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let isDirectory: Bool
    var children: [FileNode] = []

    init(name: String, path: String, isDirectory: Bool) {
        self.name = name
        self.path = path
        self.isDirectory = isDirectory
    }
}

struct FileTreeNodeView: View {
    let node: FileNode
    @Binding var expandedNodes: Set<String>
    let level: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer().frame(width: CGFloat(level) * 16)

                if node.isDirectory {
                    Image(systemName: expandedNodes.contains(node.path) ? "chevron.down" : "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: 12)
                        .onTapGesture {
                            if expandedNodes.contains(node.path) {
                                expandedNodes.remove(node.path)
                            } else {
                                expandedNodes.insert(node.path)
                            }
                        }
                } else {
                    Spacer().frame(width: 12)
                }

                Image(systemName: iconName)
                    .foregroundColor(node.isDirectory ? .blue : .secondary)

                Text(node.name)
                    .font(.subheadline)

                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.vertical, 8)
            .onTapGesture {
                if node.isDirectory {
                    if expandedNodes.contains(node.path) {
                        expandedNodes.remove(node.path)
                    } else {
                        expandedNodes.insert(node.path)
                    }
                }
            }

            if node.isDirectory && expandedNodes.contains(node.path) {
                ForEach(node.children) { child in
                    FileTreeNodeView(node: child, expandedNodes: $expandedNodes, level: level + 1)
                }
            }
        }
    }

    private var iconName: String {
        if node.isDirectory { return "folder.fill" }
        let ext = (node.name as NSString).pathExtension.lowercased()
        switch ext {
        case "swift": return "swift"
        case "md": return "doc.text"
        case "json": return "curlybraces"
        default: return "doc"
        }
    }
}
