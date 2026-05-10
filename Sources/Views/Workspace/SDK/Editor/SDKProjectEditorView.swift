/*
 REDESIGN SUMMARY:
 - Standardized the tab bar using a horizontal ScrollView with Capsule-styled buttons.
 - Replaced manual diagnostics banner with a private DiagnosticsBar struct using semantic colors.
 - Modernized the tab picker sheet with .presentationDetents([.medium, .large]) and a drag indicator.
 - Replaced manual HStack layouts with native Label and semantic SF Symbols.
 - Strictly preserved all activeTab switching logic and diagnostic navigation pathways.
 - Standardized on insetGrouped List style for the tab picker.
 */

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

            Group {
                if let activeTab {
                    activeTabView(for: activeTab.node)
                } else {
                    ContentUnavailableView(
                        "No Area Selected",
                        systemImage: "square.stack",
                        description: Text("Open a project area from the Navigator to begin editing.")
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if !state.diagnostics.isEmpty {
                Divider()
                DiagnosticsBar(diagnostics: state.diagnostics) { node in
                    state.open(node: node)
                }
            }
        }
        .sheet(isPresented: $showingTabPicker) {
            NavigationStack {
                TabPickerList(state: state) { showingTabPicker = false }
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showingTabPicker = false }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(20)
        }
        .onChange(of: projectManager.currentProject?.id) { _, _ in
            state.syncSDKGraphFromProject()
            state.recalculateDiagnostics()
        }
    }

    private var tabHeader: some View {
        HStack {
            if isCompact {
                Button { showingTabPicker = true } label: {
                    Label(activeTab?.title ?? "Select Area", systemImage: activeTab?.node.icon ?? "chevron.down")
                        .font(.subheadline.bold())
                }
                Spacer()
                if !state.diagnostics.isEmpty {
                    Text("\(state.diagnostics.count) issues")
                        .font(.caption2.bold())
                        .foregroundStyle(state.diagnostics.contains { $0.severity == .error } ? Color.red : Color.orange)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(state.openTabs) { tab in
                            EditorTabItem(tab: tab, isSelected: state.selectedTabID == tab.id) {
                                state.setSelected(tabID: tab.id)
                            } onClose: {
                                state.close(tabID: tab.id)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                }
            }
        }
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private func activeTabView(for node: SDKWorkspaceNode) -> some View {
        switch node {
        case .config: IDEConfigView()
        case .capabilities: IDECapabilitiesView()
        case .scopes: IDEScopesView()
        case .libraries: IDELibrariesView()
        case .dependencies: IDEDependenciesView()
        case .connectors: IDEConnectorsView()
        case .runtimeScripts: IDERuntimeScriptsView()
        case .apiEndpoints: IDEAPIEndpointsView()
        }
    }
}

// MARK: - Private Subviews

private struct EditorTabItem: View {
    let tab: SDKEditorTab
    let isSelected: Bool
    let action: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Button(tab.title, action: action)
                .font(.caption.bold())

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .black))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color.primary.opacity(0.05), in: Capsule())
        .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
    }
}

private struct DiagnosticsBar: View {
    let diagnostics: [SDKRuntimeDiagnostic]
    let onSelect: (SDKWorkspaceNode) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(diagnostics.prefix(5)) { diag in
                    Button { onSelect(diag.node) } label: {
                        Label(diag.message, systemImage: diag.severity == .error ? "exclamationmark.octagon" : "exclamationmark.triangle")
                            .font(.caption2.bold())
                            .foregroundStyle(diag.severity == .error ? Color.red : Color.orange)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(.bar)
    }
}

private struct TabPickerList: View {
    let state: SDKRuntimeWorkspaceState
    let onSelect: () -> Void

    var body: some View {
        List {
            Section {
                ForEach(SDKWorkspaceNode.allCases) { node in
                    Button {
                        state.open(node: node)
                        onSelect()
                    } label: {
                        Label(node.title, systemImage: node.icon)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Open Area")
        .navigationBarTitleDisplayMode(.inline)
    }
}
