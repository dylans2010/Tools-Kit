import SwiftUI

struct SDKProjectEditorView: View {
    @StateObject private var state = SDKRuntimeWorkspaceState.shared
    @StateObject private var projectManager = SDKProjectManager.shared

    var body: some View {
        VStack(spacing: 0) {
            tabStrip
            Divider()
            activeTabView
            if !state.diagnostics.isEmpty {
                Divider()
                diagnosticsBanner
            }
        }
        .onChange(of: projectManager.currentProject?.id) { _, _ in
            state.recalculateDiagnostics()
        }
    }

    private var tabStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(state.openTabs) { tab in
                    HStack(spacing: 6) {
                        Button(tab.title) {
                            state.setSelected(tabID: tab.id)
                        }
                        .buttonStyle(.borderless)
                        .font(.caption.weight(state.selectedTabID == tab.id ? .semibold : .regular))
                        if state.openTabs.count > 1 {
                            Button {
                                state.close(tabID: tab.id)
                            } label: {
                                Image(systemName: "xmark")
                            }
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

    @ViewBuilder
    private var activeTabView: some View {
        if let activeTab = state.openTabs.first(where: { $0.id == state.selectedTabID }) ?? state.openTabs.first {
            switch activeTab.node {
            case .config:
                configView
            case .capabilities:
                SDKCapabilitiesMatrixView()
            case .scopes:
                SDKScopesEditorView()
            case .libraries:
                SDKLibraryManagerView()
            case .dependencies:
                SDKDependencyManagerView()
            case .connectors:
                SDKConnectorsView()
            case .runtimeScripts:
                SDKFlowBuilderView(project: Binding(
                    get: { projectManager.currentProject ?? SDKProject(name: "Runtime") },
                    set: { projectManager.currentProject = $0; state.recalculateDiagnostics() }
                ))
            case .apiEndpoints:
                SDKAPIExplorerView()
            }
        } else {
            ContentUnavailableView("No tab selected", systemImage: "rectangle.stack", description: Text("Select a project editor tab to continue."))
        }
    }

    private var diagnosticsBanner: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(state.diagnostics.prefix(4)) { diagnostic in
                Label {
                    Text(diagnostic.message)
                        .lineLimit(1)
                } icon: {
                    Image(systemName: diagnostic.severity == .error ? "xmark.octagon.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(diagnostic.severity == .error ? .red : .orange)
                }
                .font(.caption)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
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
                ))
            }
            Section("Runtime Preview") {
                Text("Open tabs: \(state.openTabs.count)")
                Text("Diagnostics: \(state.diagnostics.count)")
                Text("Memory estimate: \(state.memoryEstimateMB) MB")
            }
        }
        .formStyle(.grouped)
    }
}
