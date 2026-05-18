import SwiftUI

struct RuntimeInspectorDevTool: DevTool {
    let id = "runtime-inspector"
    let name = "Runtime Inspector"
    let category = DevToolCategory.debugging
    let icon = "magnifyingglass"
    let description = "Inspect live runtime objects and properties"

    func render() -> some View {
        RuntimeInspectorView()
    }
}

struct RuntimeInspectorView: View {
    @StateObject private var viewModel = RuntimeInspectorViewModel()

    var body: some View {
        let headerDescription = "Deeply inspect live objects, their property values, and internal states during execution."
        VStack(spacing: 0) {
            DevToolHeader(
                title: "Runtime Inspector",
                description: headerDescription,
                icon: "magnifyingglass"
            )
            .padding()

            List {
                Section("Live Objects") {
                    ForEach(viewModel.objects) { obj in
                        NavigationLink {
                            List {
                                ForEach(obj.properties, id: \.key) { key, val in
                                    LabeledContent(key, value: val)
                                }
                            }
                            .navigationTitle(obj.name)
                        } label: {
                            HStack {
                                Text(obj.name).font(.headline)
                                Spacer()
                                Text(obj.type).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct RuntimeObject: Identifiable {
    let id = UUID()
    let name: String
    let type: String
    let properties: [String: String]
}

class RuntimeInspectorViewModel: ObservableObject {
    @Published var objects: [RuntimeObject] = [
        RuntimeObject(name: "ToolsKitSDK.shared", type: "ToolsKitSDK", properties: ["isSyncing": "false", "isInitialized": "true"]),
        RuntimeObject(name: "SDKConfigManager.shared", type: "SDKConfigManager", properties: ["activeProfile": "Default"])
    ]
}
