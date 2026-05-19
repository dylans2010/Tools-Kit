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
    @State private var searchText = ""

    var body: some View {
        List {
            Section("System Health") {
                HStack(spacing: 12) {
                    HealthCircle(label: "Active", count: registry.modules.count, color: .green)
                    HealthCircle(label: "Loading", count: 2, color: .blue)
                    HealthCircle(label: "Errored", count: 0, color: .red)
                }
                .padding(.vertical, 8)
            }

            Section {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Filter modules...", text: $searchText)
                }
            }

            Section("Registered Modules") {
                if filteredModules.isEmpty {
                    Text("No modules found matching '\(searchText)'")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(filteredModules) { module in
                        ModuleRow(module: module)
                            .onTapGesture { selectedModule = module }
                    }
                }
            }
        }
        .navigationTitle("Module Inspector")
        .sheet(item: $selectedModule) { (module: _DTModuleDescriptor) in
            ModuleDetailView(module: module)
        }
    }

    private var filteredModules: [_DTModuleDescriptor] {
        if searchText.isEmpty { return registry.modules }
        return registry.modules.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.id.localizedCaseInsensitiveContains(searchText)
        }
    }
}

struct HealthCircle: View {
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct ModuleRow: View {
    fileprivate let module: _DTModuleDescriptor

    var body: some View {
        HStack {
            Image(systemName: "puzzlepiece.extension.fill")
                .foregroundStyle(.blue)
                .font(.title3)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(module.name).font(.subheadline.bold())
                Text(module.id).font(.system(size: 9, design: .monospaced)).foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("v\(module.version)")
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(.systemGray5), in: Capsule())

                HStack(spacing: 4) {
                    Circle().fill(.green).frame(width: 6, height: 6)
                    Text("ACTIVE").font(.system(size: 7, weight: .black)).foregroundStyle(.green)
                }
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 2)
    }
}

struct ModuleDetailView: View {
    fileprivate let module: _DTModuleDescriptor
    @Environment(\.dismiss) var dismiss
    @State private var activeTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("View", selection: $activeTab) {
                    Text("Details").tag(0)
                    Text("Dependencies").tag(1)
                    Text("Manifest").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()

                List {
                    if activeTab == 0 {
                        detailsSection
                    } else if activeTab == 1 {
                        dependenciesSection
                    } else {
                        manifestSection
                    }
                }
            }
            .navigationTitle(module.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var detailsSection: some View {
        Group {
            Section("Info") {
                LabeledContent("Identifier", value: module.id)
                LabeledContent("Version", value: module.version)
                LabeledContent("Build", value: "24A102")
                LabeledContent("Loaded At", value: "2024-05-20 14:22:01")
            }

            Section("Capabilities (\(module.capabilities.count))") {
                if module.capabilities.isEmpty {
                    Text("No capabilities exported.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(module.capabilities, id: \.self) { cap in
                        HStack {
                            Image(systemName: "bolt.fill").foregroundStyle(.orange).font(.caption)
                            Text(cap).font(.subheadline)
                        }
                    }
                }
            }
        }
    }

    private var dependenciesSection: some View {
        Section {
            Label("SDKCore (v2.0+)", systemImage: "link")
            Label("DataEngine (v1.5+)", systemImage: "link")
            Label("SecurityManager", systemImage: "link")
        } header: {
            Text("Required Modules")
        }
    }

    private var manifestSection: some View {
        Section {
            Text("""
            {
              "id": "\(module.id)",
              "name": "\(module.name)",
              "version": "\(module.version)",
              "capabilities": \(module.capabilities.description),
              "priority": 100,
              "sandbox": true
            }
            """)
            .font(.system(size: 11, design: .monospaced))
            .padding(.vertical, 8)
        } header: {
            Text("Raw JSON Manifest")
        }
    }
}

#Preview {
    SDKModuleInspectorView()
}
