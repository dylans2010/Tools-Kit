import SwiftUI

struct SDKCapabilityMatrixView: View {
    @StateObject private var projectManager = SDKProjectManager.shared
    @State private var searchText = ""

    var body: some View {
        List {
            Section(header: Text("Global Capability Overview")) {
                Text("This matrix shows all available SDK capabilities and their status across your current project.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let project = projectManager.currentProject {
                Section(header: Text("Project: \(project.name)")) {
                    ForEach(SDKScope.allCases.filter {
                        searchText.isEmpty || $0.displayName.localizedCaseInsensitiveContains(searchText)
                    }) { scope in
                        CapabilityToggleRow(scope: scope, isEnabled: project.enabledScopes.contains(String(describing: scope)))
                    }
                }
            } else {
                ContentUnavailableView("No Project", systemImage: "cube.transparent", description: Text("Select a project to view its capability matrix."))
            }
        }
        .navigationTitle("Capability Matrix")
        .searchable(text: $searchText, prompt: "Filter capabilities")
    }
}

private struct CapabilityToggleRow: View {
    let scope: SDKScope
    let isEnabled: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(scope.displayName)
                    .font(.subheadline.bold())
                Text(scope.rawValue)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if isEnabled {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
