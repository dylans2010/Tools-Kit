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
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
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
                        Label(activeTab?.title ?? "Config", systemImage: activeTab?.node.icon ?? "square.stack")
                            .font(.subheadline.weight(.semibold))
                    }
                    Spacer()
                    Text("\(state.diagnostics.count) issues")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(state.diagnostics.contains { $0.severity == .error } ? .red : .secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.bar)
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
                        if state.openTabs.count > 1 {
                            Button { state.close(tabID: tab.id) } label: { Image(systemName: "xmark") }
                                .buttonStyle(.borderless)
                                .font(.caption2)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(state.selectedTabID == tab.id ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.08), in: Capsule())
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
    }

    private var tabPicker: some View {
        List {
            Section("Workspace") {
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
            ContentUnavailableView("No tab selected", systemImage: "rectangle.stack", description: Text("Select a project editor tab to continue."))
        }
    }

    private var diagnosticsBanner: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(state.diagnostics.prefix(isCompact ? 2 : 4)) { diagnostic in
                    Label {
                        Text(diagnostic.message).lineLimit(1)
                    } icon: {
                        Image(systemName: diagnostic.severity == .error ? "xmark.octagon.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(diagnostic.severity == .error ? .red : .orange)
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(.regularMaterial, in: Capsule())
                    .onTapGesture { state.open(node: diagnostic.node) }
                }
            }
            .padding(8)
        }
        .background(.bar)
    }

    private var configView: some View {
        Form {
            Section("Project") {
                TextField("Name", text: Binding(
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
                Picker("Status", selection: Binding(
                    get: { projectManager.currentProject?.status ?? .draft },
                    set: {
                        guard var project = projectManager.currentProject else { return }
                        project.status = $0
                        projectManager.updateProject(project)
                    }
                )) {
                    ForEach(SDKProject.ProjectStatus.allCases, id: \.self) { status in
                        Text(status.rawValue.capitalized).tag(status)
                    }
                }
            }
            Section("SDK Runtime") {
                LabeledContent("Run configuration", value: state.selectedRunConfiguration?.name ?? "Default Sandbox")
                LabeledContent("Effective scopes", value: "\(state.effectiveScopes(for: projectManager.currentProject).count)")
                LabeledContent("Libraries", value: "\(state.libraries.count)")
                LabeledContent("Dependencies", value: "\(state.dependencies.count)")
                LabeledContent("Memory estimate", value: "\(state.memoryEstimateMB) MB")
                Button("Sync Project With SDK Graph") {
                    state.syncSDKGraphFromProject()
                    state.recalculateDiagnostics()
                }
            }
        }
        .formStyle(.grouped)
    }
}
