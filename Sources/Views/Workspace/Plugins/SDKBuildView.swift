import SwiftUI

struct SDKBuildView: View {
    @StateObject private var runtime = SDKRuntimeEngine.shared
    @StateObject private var stateManager = SDKStateManager.shared

    @State private var selectedProject: SDKProject?
    @State private var showingDashboard = true
    @State private var showingSystemExplorer = false
    @State private var showingConsole = false
    @State private var showingDataFetch = false

    var body: some View {
        NavigationStack {
            ZStack {
                if showingDashboard {
                    SDKProjectDashboardView(selectedProject: $selectedProject)
                } else if let project = selectedProject {
                    ProjectEditorView(project: project)
                } else {
                    ContentUnavailableView("Select a Project", systemImage: "hammer", description: Text("Choose a project from the dashboard to start editing."))
                }
            }
            .navigationTitle("Build with ToolsKit")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button { showingDataFetch = true } label: { Label("Fetch Data", systemImage: "arrow.down.doc") }
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
            .sheet(isPresented: $showingDataFetch) {
                NavigationStack { SDKFetchConfigView() }
            }
        }
    }
}

struct SDKFetchConfigView: View {
    @State private var selectedTypes: Set<SDKDataType> = [.notes]
    @State private var selectedScopes: Set<PluginCapability> = [.notes, .tasks]
    @State private var mode: SDKFetchMode = .full
    @State private var includeRelations = false
    @State private var includeHistory = false
    @State private var result: SDKFetchResult?
    @State private var isFetching = false

    @Environment(\.dismiss) var dismiss

    var body: some View {
        Form {
            Section("Data Configuration") {
                List(SDKDataType.allCases, id: \.self) { type in
                    Toggle(type.rawValue.capitalized, isOn: Binding(
                        get: { selectedTypes.contains(type) },
                        set: { if $0 { selectedTypes.insert(type) } else { selectedTypes.remove(type) } }
                    ))
                }

                Picker("Fetch Mode", selection: $mode) {
                    Text("Full").tag(SDKFetchMode.full)
                    Text("Partial").tag(SDKFetchMode.partial)
                    Text("Snapshot").tag(SDKFetchMode.snapshot)
                    Text("Diff").tag(SDKFetchMode.diff)
                }
            }

            Section("Scopes (Security)") {
                ForEach([PluginCapability.notes, .tasks, .mail, .calendar, .files, .workspaceFetchFullData, .sdkDeveloperNoSandbox]) { cap in
                    Toggle(cap.displayName, isOn: Binding(
                        get: { selectedScopes.contains(cap) },
                        set: { if $0 { selectedScopes.insert(cap) } else { selectedScopes.remove(cap) } }
                    ))
                }
            }

            Section("Options") {
                Toggle("Include Relations", isOn: $includeRelations)
                Toggle("Include History", isOn: $includeHistory)
            }

            Section {
                Button(action: runFetch) {
                    if isFetching {
                        ProgressView().progressViewStyle(.circular)
                    } else {
                        Text("Execute Fetch")
                    }
                }
                .disabled(selectedTypes.isEmpty || isFetching)
            }

            if let result = result {
                Section("Result Summary") {
                    NavigationLink("View \(result.data.count) Results") {
                        SDKDataInspectorView(result: result)
                    }
                    Text("Fetch Time: \(String(format: "%.3f", result.performance.fetchTime))s")
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Fetch Workspace Data")
        .alert("SDK Unrestricted Access", isPresented: $showingNoSandboxWarning) {
            Button("Cancel", role: .cancel) { }
            Button("Proceed", role: .destructive) { performFetch() }
        } message: {
            Text("You are attempting to fetch data with unrestricted developer access (noSandbox). This will bypass all security checks and log all activity. Proceed with caution.")
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
    }

    @State private var showingNoSandboxWarning = false

    private func runFetch() {
        if selectedScopes.contains(.sdkDeveloperNoSandbox) {
            showingNoSandboxWarning = true
            return
        }
        performFetch()
    }

    private func performFetch() {
        isFetching = true
        let request = SDKFetchRequest(
            dataTypes: Array(selectedTypes),
            mode: mode,
            scopes: Array(selectedScopes),
            includeRelations: includeRelations,
            includeHistory: includeHistory
        )

        Task {
            do {
                let fetchResult = try await ToolsKitSDK.shared.fetchData(request)
                await MainActor.run {
                    self.result = fetchResult
                    self.isFetching = false
                }
            } catch {
                await MainActor.run {
                    self.isFetching = false
                    SDKConsoleView.LogBus.shared.log("Fetch Failed: \(error.localizedDescription)", type: .error)
                }
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
