

import SwiftUI

struct IDERuntimeScriptsView: View {
    @StateObject private var projectManager = SDKProjectManager.shared
    @StateObject private var state = SDKRuntimeWorkspaceState.shared

    var body: some View {
        SDKFlowBuilderView(project: Binding(
            get: { projectManager.currentProject ?? SDKProject(name: "Runtime") },
            set: {
                projectManager.currentProject = $0
                state.syncSDKGraphFromProject($0)
                state.recalculateDiagnostics()
            }
        ))
        .navigationTitle("Runtime Scripts")
        .navigationBarTitleDisplayMode(.inline)
    }
}
