import SwiftUI

struct SDKAssetOptimizerView: View {
    @StateObject private var dataEngine = SDKDataEngine.shared
    @StateObject private var projectManager = SDKProjectManager.shared

    @State private var optimizationResults: String?
    @State private var selectedOptions: Set<String> = ["Cache", "Temporary Files"]

    let options = ["Cache", "Temporary Files", "Diagnostic Logs"]

    var body: some View {
        List {
            Section("Optimization Targets") {
                Text("Select components to optimize and clear to reduce the SDK's footprint during development.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(options, id: \.self) { option in
                    Toggle(option, isOn: Binding(
                        get: { selectedOptions.contains(option) },
                        set: { isOn in
                            if isOn {
                                selectedOptions.insert(option)
                            } else {
                                selectedOptions.remove(option)
                            }
                        }
                    ))
                }
            }

            Section("Action") {
                Button(action: runOptimizer) {
                    Label("Run Asset Optimizer", systemImage: "wand.and.stars")
                }
                .disabled(selectedOptions.isEmpty)
            }

            if let results = optimizationResults {
                Section("Results") {
                    Label(results, systemImage: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.green)
                }
            }

            Section("Status") {
                LabeledContent("Cache Status", value: dataEngine.isInitialized ? "Active" : "Invalid")
                if let project = projectManager.currentProject {
                    LabeledContent("Project", value: project.name)
                }
            }
        }
        .navigationTitle("Asset Optimizer")
    }

    private func runOptimizer() {
        optimizationResults = nil

        // Perform real cache invalidation if selected
        if selectedOptions.contains("Cache") {
            dataEngine.invalidateCache()
        }

        // Perform real temporary file cleanup if selected
        if selectedOptions.contains("Temporary Files") {
            let fileManager = FileManager.default
            let tempDir = fileManager.temporaryDirectory
            if let files = try? fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil) {
                for file in files where file.pathExtension == "sdkbundle" || file.lastPathComponent.contains("encoded_") {
                    try? fileManager.removeItem(at: file)
                }
            }
        }

        // Clear logs if selected
        if selectedOptions.contains("Diagnostic Logs") {
            SDKLogStore.shared.clear()
        }

        optimizationResults = "Successfully optimized \(selectedOptions.count) targets. System resources reclaimed."

        SDKAuditLogger.shared.log(
            eventType: .security,
            projectID: projectManager.currentProject?.id,
            scope: "system.optimization",
            message: "Performed asset optimization: \(selectedOptions.joined(separator: ", "))"
        )
    }
}
