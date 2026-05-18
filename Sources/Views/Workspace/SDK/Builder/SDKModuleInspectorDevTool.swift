import SwiftUI

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
    @StateObject private var registry = SDKModuleRegistry.shared
    @State private var selectedModule: SDKModuleDescriptor?

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "SDK Module Inspector",
                description: "Deep dive into the registered SDK modules, their capabilities, and activation status.",
                icon: "puzzlepiece.fill"
            )
            .padding()

            List {
                Section("Registered Modules") {
                    ForEach(registry.modules) { module in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(module.displayName).font(.headline)
                                Text(module.identifier).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            StatusBadge(
                                text: registry.activeModuleIDs.contains(module.id) ? "Active" : "Idle",
                                color: registry.activeModuleIDs.contains(module.id) ? .green : .secondary
                            )
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { selectedModule = module }
                    }
                }
            }
        }
        .sheet(item: $selectedModule) { module in
            ModuleDetailView(module: module)
        }
    }
}

struct ModuleDetailView: View {
    let module: SDKModuleDescriptor
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("General") {
                    LabeledContent("Version", value: module.version)
                    LabeledContent("Min SDK", value: module.minimumSDKVersion)
                    LabeledContent("Priority", value: "\(module.loadPriority)")
                }

                Section("Capabilities") {
                    ForEach(module.capabilities, id: \.self) { cap in
                        Label(cap.rawValue, systemImage: "checkmark.circle.fill")
                    }
                }

                Section("Dependencies") {
                    if module.dependencies.isEmpty {
                        Text("None").foregroundStyle(.secondary)
                    } else {
                        ForEach(module.dependencies, id: \.self) { dep in
                            Text(dep)
                        }
                    }
                }
            }
            .navigationTitle(module.displayName)
            .toolbar {
                Button("Done") { dismiss() }
            }
        }
    }
}
