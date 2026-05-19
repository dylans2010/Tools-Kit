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
    @State private var searchText = ""

    var body: some View {
        List {
            Section("Runtime Summary") {
                HStack(spacing: 20) {
                    RuntimeMetric(label: "Object Nodes", value: "\(viewModel.objects.count)", color: .blue)
                    RuntimeMetric(label: "Allocations", value: "142", color: .green)
                    RuntimeMetric(label: "Leakers", value: "0", color: .red)
                }
                .padding(.vertical, 8)
            }

            Section("Memory Layout (Simulated)") {
                HStack(spacing: 4) {
                    ForEach(0..<10) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(i < 7 ? Color.blue : Color.gray.opacity(0.2))
                            .frame(height: 20)
                    }
                }
                Text("Heap utilization: 72%").font(.caption2).foregroundStyle(.secondary)
            }

            Section("Live Object Tree") {
                ForEach(filteredObjects) { object in
                    NavigationLink {
                        ObjectDetailView(object: object)
                    } label: {
                        HStack {
                            Image(systemName: "cube.fill")
                                .foregroundStyle(.blue)
                                .font(.caption)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(object.name).font(.subheadline.bold())
                                Text(object.type).font(.system(size: 9, design: .monospaced)).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section {
                Button { viewModel.performGC() } label: {
                    Label("Trigger Garbage Collection", systemImage: "trash.fill")
                }

                Button { viewModel.dumpHeap() } label: {
                    Label("Dump Heap to Console", systemImage: "terminal")
                }
            }
        }
        .navigationTitle("Runtime Lab")
        .searchable(text: $searchText, prompt: "Search objects...")
    }

    private var filteredObjects: [RuntimeObject] {
        if searchText.isEmpty { return viewModel.objects }
        return viewModel.objects.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.type.localizedCaseInsensitiveContains(searchText) }
    }
}

struct RuntimeMetric: View {
    let label: String
    let value: String
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 8, weight: .black)).foregroundStyle(.secondary).textCase(.uppercase)
            Text(value).font(.headline.bold()).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(color.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
    }
}

struct ObjectDetailView: View {
    let object: RuntimeObject

    var body: some View {
        List {
            Section("Properties") {
                ForEach(Array(object.properties.sorted(by: { $0.key < $1.key })), id: \.key) { key, value in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(key).font(.system(size: 8, weight: .black)).foregroundStyle(.blue).textCase(.uppercase)
                        Text(value).font(.system(size: 11, design: .monospaced))
                    }
                    .padding(.vertical, 2)
                }
            }

            Section("Memory Statistics") {
                LabeledContent("Retain Count", value: "1")
                LabeledContent("Address", value: "0x\(String(format: "%012lX", Int.random(in: 0...1000000)))")
                LabeledContent("Size", value: "64 bytes")
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
        RuntimeObject(name: "ToolsKitSDK.shared", type: "ToolsKitSDK", properties: ["isSyncing": "false", "isInitialized": "true", "authStatus": "authenticated"]),
        RuntimeObject(name: "SDKConfigManager.shared", type: "SDKConfigManager", properties: ["activeProfile": "Default", "overrideCount": "12"]),
        RuntimeObject(name: "SDKDataEngine.shared", type: "SDKDataEngine", properties: ["cacheEnabled": "true", "bufferSize": "1024KB"]),
        RuntimeObject(name: "SDKEventBus.shared", type: "SDKEventBus", properties: ["subscriberCount": "4", "eventCount": "1520"])
    ]

    func performGC() {
        // Simulation
    }

    func dumpHeap() {
        // Simulation
    }
}

#Preview {
    RuntimeInspectorView()
}
