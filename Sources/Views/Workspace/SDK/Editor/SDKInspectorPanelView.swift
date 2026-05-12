

import SwiftUI

struct SDKInspectorPanelView: View {
    @StateObject private var state = SDKRuntimeWorkspaceState.shared
    @State private var editorMode: InspectorMode = .form
    @State private var jsonDraft = "{}"
    @State private var jsonError: String?

    enum InspectorMode: String, CaseIterable, Sendable {
        case form = "Details", json = "JSON"
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Mode", selection: $editorMode) {
                ForEach(InspectorMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(12)

            Divider()

            Group {
                switch editorMode {
                case .form:
                    FormInspector(state: state)
                case .json:
                    JSONEditor(jsonDraft: $jsonDraft, jsonError: $jsonError, state: state)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .onAppear { jsonDraft = state.inspectorJSON }
    }
}

// MARK: - Private Subviews

private struct FormInspector: View {
    let state: SDKRuntimeWorkspaceState

    var body: some View {
        Form {
            Section {
                LabeledContent("Area", value: state.selectedNode.title)
                LabeledContent("Tabs", value: "\(state.openTabs.count)")
            } header: {
                Label("Active Context", systemImage: "scope")
            }

            Section {
                LabeledContent("Config Count", value: "\(state.runConfigurations.count)")
                LabeledContent("Memory", value: "\(state.memoryEstimateMB) MB")
            } header: {
                Label("Runtime Profile", systemImage: "cpu")
            }

            Section {
                LabeledContent("Scopes", value: "\(SDKProjectManager.shared.currentProject?.enabledScopes.count ?? 0)")
                LabeledContent("Libraries", value: "\(state.libraries.count)")
                LabeledContent("Dependencies", value: "\(state.dependencies.count)")
            } header: {
                Label("Security & Modules", systemImage: "lock.shield")
            }
        }
    }
}

private struct JSONEditor: View {
    @Binding var jsonDraft: String
    @Binding var jsonError: String?
    let state: SDKRuntimeWorkspaceState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextEditor(text: $jsonDraft)
                .font(.system(.caption, design: .monospaced))
                .frame(maxHeight: .infinity)
                .padding(8)
                .background(.background, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.1)))

            if let error = jsonError {
                Label(error, systemImage: "exclamationmark.octagon.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack {
                Button { validate() } label: {
                    Label("Validate", systemImage: "checkmark.circle")
                }
                .buttonStyle(.bordered)
                Spacer()
                Button { apply() } label: {
                    Label("Apply Changes", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(12)
    }

    private func validate() {
        if let data = jsonDraft.data(using: .utf8), (try? JSONSerialization.jsonObject(with: data)) != nil {
            jsonError = nil
        } else {
            jsonError = "Invalid JSON structure."
        }
    }

    private func apply() {
        validate()
        if jsonError == nil { state.inspectorJSON = jsonDraft }
    }
}
