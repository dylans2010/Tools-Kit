import SwiftUI

private struct _DTModuleDescriptor: Identifiable, Hashable {
    let id: String; let name: String; let version: String
    var dependencies: [String]
    init(id: String, name: String, version: String = "1.0",
         dependencies: [String] = []) {
        self.id = id; self.name = name
        self.version = version; self.dependencies = dependencies
    }
}

private class _DTModuleRegistry: ObservableObject {
    static let shared = _DTModuleRegistry()
    @Published var modules: [_DTModuleDescriptor] = []
    private init() {}
}

struct SDKDependencyGraphDevTool: DevTool {
    let id = "sdk-dependency-graph"
    let name = "Dependency Graph"
    let category = DevToolCategory.debugging
    let icon = "circle.grid.cross.fill"
    let description = "Visualize module dependency mapping"

    func render() -> some View {
        SDKDependencyGraphView()
    }
}

struct SDKDependencyGraphView: View {
    @StateObject private var registry = _DTModuleRegistry.shared

    var body: some View {
        let orderedModules = registry.modules
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(orderedModules) { module in
                    HStack(alignment: .top) {
                        Circle().fill(Color.accentColor).frame(width: 8, height: 8).padding(.top, 6)
                        VStack(alignment: .leading) {
                            Text(module.name).font(.headline)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    SDKDependencyGraphView()
}
