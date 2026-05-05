import SwiftUI

struct SDKBuildView: View {
    @StateObject private var runtime = SDKRuntimeEngine.shared
    @StateObject private var stateManager = SDKStateManager.shared

    @State private var selectedProject: SDKProject?
    @State private var showingDashboard = true
    @State private var showingSystemExplorer = false
    @State private var showingConsole = false

    var body: some View {
        NavigationStack {
            ZStack {
                if showingDashboard {
                    SDKProjectDashboardView(selectedProject: $selectedProject)
                } else if let project = selectedProject {
                    ProjectEditorView(project: project)
                } else {
                    ContentUnavailableView("Select a Project", systemImage: "hammer")
                }
            }
            .navigationTitle("Build with ToolsKit")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button { showingSystemExplorer = true } label: { Label("Explorer", systemImage: "network") }
                    Button { showingConsole = true } label: { Label("Console", systemImage: "terminal") }
                }

                ToolbarItem(placement: .bottomBar) {
                    Toggle(isOn: $runtime.isNoSandboxModeEnabled) {
                        Label("Try with SDK", systemImage: "shield.slash")
                    }
                    .toggleStyle(.button)
                    .tint(.red)
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    if !showingDashboard {
                        Button("Back") { showingDashboard = true }
                    }
                }
            }
            .sheet(isPresented: $showingSystemExplorer) {
                NavigationStack { SDKSystemExplorerView() }
            }
            .sheet(isPresented: $showingConsole) {
                NavigationStack { SDKConsoleView() }
            }
        }
    }
}

struct ProjectEditorView: View {
    @State var project: SDKProject
    @StateObject private var runtime = SDKRuntimeEngine.shared
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("View", selection: $selectedTab) {
                Text("Code").tag(0)
                Text("Flow").tag(1)
                Text("Permissions").tag(2)
                Text("Deploy").tag(3)
            }
            .pickerStyle(.segmented)
            .padding()

            Divider()

            switch selectedTab {
            case 0:
                TextEditor(text: $project.sourceCode)
                    .font(.system(.body, design: .monospaced))
                    .padding()
            case 1:
                SDKFlowBuilderView(project: $project)
            case 2:
                SDKPermissionControlView(project: $project)
            case 3:
                SDKDeploymentView(project: project)
            default:
                EmptyView()
            }

            HStack {
                Button(action: { SDKRuntimeEngine.shared.runProject(project) }) {
                    Label("Run Project", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)

                Button(action: { SDKStateManager.shared.saveProject(project) }) {
                    Label("Save", systemImage: "plus.circle")
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
    }
}
