import SwiftUI

private struct _DTModuleDescriptor: Identifiable, Hashable {
    let id: String
    let name: String
    let version: String
    var capabilities: [String]
    init(id: String, name: String, version: String = "1.0",
         capabilities: [String] = []) {
        self.id = id; self.name = name
        self.version = version; self.capabilities = capabilities
    }
}

private class _DTModuleRegistry: ObservableObject {
    static let shared = _DTModuleRegistry()
    @Published var modules: [_DTModuleDescriptor] = []
    private init() {}
}

struct SDKModuleInspectorDevTool: DevTool {
    let id = "sdk-module-inspector"
    let name = "Module Inspector"
    let category = DevToolCategory.debugging
    let icon = "puzzlepiece.fill"
    let description = "Inspect and manage SDK modules"

    func render() -> some View {
        SDKModuleInspectorView()
    }
}

struct SDKModuleInspectorView: View {
    @StateObject private var registry = _DTModuleRegistry.shared
    @State private var selectedModule: _DTModuleDescriptor?

    var body: some View {
        List {
            Section("Registered Modules") {
                ForEach(registry.modules) { module in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(module.name).font(.headline)
                            Text(module.id).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("Active")
                            .font(.caption2.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .foregroundStyle(.white)
                            .background(Color.green, in: RoundedRectangle(cornerRadius: 4))
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { selectedModule = module }
                }
            }
        }
        .sheet(item: $selectedModule) { (module: _DTModuleDescriptor) in
            ModuleDetailView(module: module)
        }
    }
}

struct ModuleDetailView: View {
    fileprivate let module: _DTModuleDescriptor
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("General") {
                    LabeledContent("Version", value: module.version)
                }

                Section("Capabilities") {
                    ForEach(module.capabilities, id: \.self) { cap in
                        Label(cap, systemImage: "checkmark.circle.fill")
                    }
                }
            }
            .navigationTitle(module.name)
            .toolbar {
                Button("Done") { dismiss() }
            }
        }
    }
}

#Preview {
    SDKModuleInspectorView()
}
