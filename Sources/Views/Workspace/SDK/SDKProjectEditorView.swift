import SwiftUI

struct SDKProjectEditorView: View {
    @StateObject private var state = SDKRuntimeWorkspaceState.shared
    @StateObject private var projectManager = SDKProjectManager.shared
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    @State private var showingTabPicker = false

    private var isCompact: Bool {
        #if os(iOS)
        return horizontalSizeClass == .compact
        #else
        return false
        #endif
    }
    private var activeTab: SDKEditorTab? { state.openTabs.first(where: { $0.id == state.selectedTabID }) ?? state.openTabs.first }

    var body: some View {
        VStack(spacing: 0) {
            tabHeader
            Divider()
            activeTabView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            if !state.diagnostics.isEmpty {
                Divider()
                diagnosticsBanner
            }
        }
        .sheet(isPresented: $showingTabPicker) {
            NavigationStack {
                tabPicker
                    .navigationTitle("Open SDK Area")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { showingTabPicker = false } } }
            }
            .presentationDetents([.medium])
        }
        .onChange(of: projectManager.currentProject?.id) { _, _ in
            state.syncSDKGraphFromProject()
            state.recalculateDiagnostics()
        }
    }

    private var tabHeader: some View {
        Group {
            if isCompact {
                HStack {
                    Button { showingTabPicker = true } label: {
                        HStack(spacing: 8) {
                            Image(systemName: activeTab?.node.icon ?? "square.stack")
                                .foregroundStyle(.accent)
                            Text(activeTab?.title ?? "Config")
                                .font(.subheadline.bold())
                                .foregroundStyle(.primary)
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.accentColor.opacity(0.1), in: Capsule())
                    }
                    Spacer()
                    if !state.diagnostics.isEmpty {
                        SDKStatusPill(status: .warning, text: "\(state.diagnostics.count) ISSUES")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.thinMaterial)
            } else {
                tabStrip
            }
        }
    }

    private var tabStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(state.openTabs) { tab in
                    HStack(spacing: 6) {
                        Button(tab.title) { state.setSelected(tabID: tab.id) }
                            .buttonStyle(.borderless)
                            .font(.caption.weight(state.selectedTabID == tab.id ? .semibold : .regular))
                            .foregroundStyle(state.selectedTabID == tab.id ? .primary : .secondary)
                        if state.openTabs.count > 1 {
                            Button { state.close(tabID: tab.id) } label: { Image(systemName: "xmark") }
                                .buttonStyle(.borderless)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(state.selectedTabID == tab.id ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .background(.thinMaterial)
    }

    private var tabPicker: some View {
        List {
            Section("Workspace Navigation") {
                ForEach(SDKWorkspaceNode.allCases) { node in
                    Button {
                        state.open(node: node)
                        showingTabPicker = false
                    } label: {
                        Label(node.title, systemImage: node.icon)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var activeTabView: some View {
        if let activeTab {
            switch activeTab.node {
            case .config: configView
            case .capabilities: SDKCapabilitiesMatrixView()
            case .scopes: SDKScopesEditorView()
            case .libraries: SDKLibraryManagerView()
            case .dependencies: SDKDependencyManagerView()
            case .connectors: SDKConnectorsView()
            case .runtimeScripts:
                SDKFlowBuilderView(project: Binding(
                    get: { projectManager.currentProject ?? SDKProject(name: "Runtime") },
                    set: { projectManager.currentProject = $0; state.syncSDKGraphFromProject($0); state.recalculateDiagnostics() }
                ))
            case .apiEndpoints: SDKAPIExplorerView()
            }
        } else {
            ContentUnavailableView("No active tab", systemImage: "square.stack.3d.up.fill", description: Text("Select an editor tab to view content."))
        }
    }

    private var diagnosticsBanner: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(state.diagnostics.prefix(4)) { diagnostic in
                    HStack(spacing: 6) {
                        Image(systemName: diagnostic.severity == .error ? "xmark.octagon.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(diagnostic.severity == .error ? .red : .orange)
                        Text(diagnostic.message)
                            .font(.caption2.bold())
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.1), in: Capsule())
                    .onTapGesture { state.open(node: diagnostic.node) }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(.ultraThinMaterial)
    }

    private var configView: some View {
        Form {
            Section {
                TextField("Project Name", text: Binding(
                    get: { projectManager.currentProject?.name ?? "" },
                    set: {
                        guard var project = projectManager.currentProject else { return }
                        project.name = $0
                        projectManager.updateProject(project)
                        state.syncSDKGraphFromProject(project)
                        state.recalculateDiagnostics()
                    }
                ))
                TextField("Description", text: Binding(
                    get: { projectManager.currentProject?.description ?? "" },
                    set: {
                        guard var project = projectManager.currentProject else { return }
                        project.description = $0
                        projectManager.updateProject(project)
                    }
                ), axis: .vertical)
            } header: {
                Text("Project Metadata")
            }

            Section {
                LabeledContent("Selected Run Config", value: state.selectedRunConfiguration?.name ?? "None")
                LabeledContent("Active Scopes", value: "\(state.effectiveScopes(for: projectManager.currentProject).count)")
                LabeledContent("Memory Footprint", value: "\(state.memoryEstimateMB) MB")
            } header: {
                Text("Runtime Context")
            }

            Section {
                Button("Sync with SDK Graph") {
                    state.syncSDKGraphFromProject()
                    state.recalculateDiagnostics()
                }
            }
        }
    }
}
