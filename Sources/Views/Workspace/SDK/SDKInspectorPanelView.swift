import SwiftUI

struct SDKInspectorPanelView: View {
    @StateObject private var state = SDKRuntimeWorkspaceState.shared
    @State private var editorMode: InspectorMode = .form
    @State private var jsonDraft = "{}"
    @State private var jsonError: String?

    enum InspectorMode: String, CaseIterable {
        case form = "Form"
        case json = "JSON"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Inspector Mode", selection: $editorMode) {
                ForEach(InspectorMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            switch editorMode {
            case .form:
                formInspector
            case .json:
                jsonInspector
            }

            if let error = jsonError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Spacer()
        }
        .padding(10)
        .onAppear { jsonDraft = state.inspectorJSON }
        .onChange(of: state.inspectorJSON) { _, newValue in
            if editorMode == .json { jsonDraft = newValue }
        }
    }

    private var formInspector: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                GroupBox("Identity") {
                    keyValue("Node", state.selectedNode.title)
                    keyValue("Tabs", "\(state.openTabs.count)")
                }
                GroupBox("Runtime Config") {
                    keyValue("Run configurations", "\(state.runConfigurations.count)")
                    keyValue("Memory estimate", "\(state.memoryEstimateMB) MB")
                }
                GroupBox("Permissions") {
                    keyValue("Project scopes", "\(SDKProjectManager.shared.currentProject?.enabledScopes.count ?? 0)")
                    keyValue("Scope diagnostics", "\(state.diagnostics.filter { $0.node == .scopes }.count)")
                }
                GroupBox("Linked Libraries") {
                    keyValue("Count", "\(state.libraries.count)")
                    keyValue("Unused", "\(state.libraries.filter { $0.usageCount == 0 }.count)")
                }
                GroupBox("Dependency Graph Hooks") {
                    keyValue("Nodes", "\(state.dependencies.count)")
                    keyValue("Conditional", "\(state.dependencies.filter { !$0.conditionalExpression.isEmpty }.count)")
                }
            }
        }
    }

    private var jsonInspector: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextEditor(text: $jsonDraft)
                .font(.system(.caption, design: .monospaced))
                .frame(minHeight: 220)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))

            HStack {
                Button("Validate") {
                    if let data = jsonDraft.data(using: .utf8), (try? JSONSerialization.jsonObject(with: data)) != nil {
                        jsonError = nil
                    } else {
                        jsonError = "Invalid JSON format."
                    }
                }
                .buttonStyle(.bordered)

                Button("Apply") {
                    if let data = jsonDraft.data(using: .utf8), (try? JSONSerialization.jsonObject(with: data)) != nil {
                        state.inspectorJSON = jsonDraft
                        jsonError = nil
                    } else {
                        jsonError = "Cannot apply invalid JSON."
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func keyValue(_ key: String, _ value: String) -> some View {
        HStack {
            Text(key).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.caption.monospaced())
        }
    }
}
