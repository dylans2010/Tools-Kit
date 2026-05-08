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
        VStack(alignment: .leading, spacing: 0) {
            Picker("Inspector Mode", selection: $editorMode) {
                ForEach(InspectorMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(10)

            Divider()

            switch editorMode {
            case .form:
                formInspector
            case .json:
                jsonInspector
            }

            if let error = jsonError {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                    Text(error)
                }
                .font(.caption)
                .foregroundStyle(.red)
                .padding()
            }

            Spacer()
        }
        .background(Color(.systemGroupedBackground))
        .onAppear { jsonDraft = state.inspectorJSON }
        .onChange(of: state.inspectorJSON) { _, newValue in
            if editorMode == .json { jsonDraft = newValue }
        }
    }

    private var formInspector: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                inspectorSection("Identity", icon: "info.circle") {
                    keyValue("Node", state.selectedNode.title)
                    keyValue("Tabs", "\(state.openTabs.count)")
                }

                inspectorSection("Runtime Config", icon: "cpu") {
                    keyValue("Configurations", "\(state.runConfigurations.count)")
                    keyValue("Memory", "\(state.memoryEstimateMB) MB")
                }

                inspectorSection("Permissions", icon: "lock.shield") {
                    keyValue("Enabled Scopes", "\(SDKProjectManager.shared.currentProject?.enabledScopes.count ?? 0)")
                    keyValue("Diagnostics", "\(state.diagnostics.filter { $0.node == .scopes }.count)")
                }

                inspectorSection("Libraries", icon: "shippingbox") {
                    keyValue("Linked", "\(state.libraries.count)")
                    keyValue("Unused", "\(state.libraries.filter { $0.usageCount == 0 }.count)")
                }

                inspectorSection("Dependencies", icon: "link") {
                    keyValue("Nodes", "\(state.dependencies.count)")
                    keyValue("Conditional", "\(state.dependencies.filter { !$0.conditionalExpression.isEmpty }.count)")
                }
            }
            .padding()
        }
    }

    private func inspectorSection<Content: View>(_ title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundStyle(.secondary)
            .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.05), lineWidth: 1))
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
        VStack(spacing: 0) {
            HStack {
                Text(key)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(value)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)

            Divider().padding(.leading, 10)
        }
    }
}
