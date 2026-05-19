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
        objectsList
    }

    private var objectsList: some View {
        List {
            Section("Live Objects") {
                ForEach(viewModel.objects) { object in
                    objectRow(for: object)
                }
            }
        }
    }

    private func objectRow(for object: RuntimeObject) -> some View {
        NavigationLink {
            objectPropertiesList(for: object)
        } label: {
            HStack {
                Text(object.name).font(.headline)
                Spacer()
                Text(object.type).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func objectPropertiesList(for object: RuntimeObject) -> some View {
        List {
            ForEach(Array(object.properties.sorted(by: { $0.key < $1.key })), id: \.key) { property in
                LabeledContent(property.key, value: property.value)
            }
        }
        .navigationTitle(object.name)
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

#Preview {
    RuntimeInspectorView()
}
