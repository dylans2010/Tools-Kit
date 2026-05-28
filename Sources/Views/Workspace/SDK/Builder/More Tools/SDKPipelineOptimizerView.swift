import SwiftUI

struct SDKPipelineOptimizerView: View {
    @StateObject private var projectManager = SDKProjectManager.shared
    @State private var optimizationLevel: Double = 0.5
    @State private var selectedDirectives: Set<String> = ["Dead Code Elimination", "Module Inlining"]
    @State private var showingSuccess = false
    @State private var message: String = ""

    let availableDirectives = [
        "Dead Code Elimination",
        "Module Inlining",
        "Static Dispatch Optimization",
        "Generic Specialization",
        "Asset Compression",
        "Dependency Pruning",
        "Metadata Stripping"
    ]

    var body: some View {
        List {
            Section(header: Text("Performance Tuning")) {
                VStack(alignment: .leading) {
                    Text("Optimization Aggression: \(Int(optimizationLevel * 100))%")
                    Slider(value: $optimizationLevel)
                }
            }

            Section(header: Text("Optimization Directives")) {
                ForEach(availableDirectives, id: \.self) { directive in
                    Toggle(directive, isOn: Binding(
                        get: { selectedDirectives.contains(directive) },
                        set: { isEnabled in
                            if isEnabled {
                                selectedDirectives.insert(directive)
                            } else {
                                selectedDirectives.remove(directive)
                            }
                        }
                    ))
                }
            }

            Section {
                Button(action: saveSettings) {
                    Label("Apply Pipeline Settings", systemImage: "bolt.fill")
                }
                .disabled(selectedDirectives.isEmpty || projectManager.currentProject == nil)
            }

            Section(header: Text("Active Pipeline")) {
                if let project = projectManager.currentProject {
                    LabeledContent("Project", value: project.name)
                    LabeledContent("Directives", value: "\(selectedDirectives.count) active")
                } else {
                    Text("No active project").foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Pipeline Optimizer")
        .alert("Settings Applied", isPresented: $showingSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(message)
        }
        .onAppear {
            loadSettings()
        }
    }

    private func loadSettings() {
        guard let project = projectManager.currentProject,
              let database = project.vulnerabilityDatabase else { return }

        if let levelStr = database["opt_level"], let level = Double(levelStr) {
            optimizationLevel = level
        }

        if let directivesStr = database["opt_directives"] {
            selectedDirectives = Set(directivesStr.components(separatedBy: ",").filter { !$0.isEmpty })
        }
    }

    private func saveSettings() {
        guard var project = projectManager.currentProject else { return }

        if project.vulnerabilityDatabase == nil {
            project.vulnerabilityDatabase = [:]
        }

        project.vulnerabilityDatabase?["opt_level"] = "\(optimizationLevel)"
        project.vulnerabilityDatabase?["opt_directives"] = Array(selectedDirectives).joined(separator: ",")
        project.updatedAt = Date()

        projectManager.updateProject(project)
        message = "Build pipeline configuration updated for \(project.name). These settings will be applied to the next 'Execute Pipeline' run."
        showingSuccess = true

        SDKAuditLogger.shared.log(
            eventType: .execution,
            projectID: project.id,
            scope: "pipeline.optimizer",
            message: "Updated pipeline build directives: \(project.vulnerabilityDatabase?["opt_directives"] ?? "")"
        )
    }
}
