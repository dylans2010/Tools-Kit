import SwiftUI

struct SDKIntegrationValidatorDevTool: DevTool {
    let id = "sdk-integration-validator"
    let name = "Integration Validator"
    let category = DevToolCategory.debugging
    let icon = "checkmark.seal.fill"
    let description = "Run SDK integration validation suite"

    func render() -> some View {
        SDKIntegrationValidatorView()
    }
}

struct SDKIntegrationValidatorView: View {
    @StateObject private var viewModel = SDKIntegrationValidatorViewModel()

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "SDK Integration Validator",
                description: "Execute a suite of automated checks to ensure the SDK is correctly integrated and configured.",
                icon: "checkmark.seal.fill"
            )
            .padding()

            List {
                Section("Validation Results") {
                    ForEach(viewModel.results) { result in
                        HStack {
                            Image(systemName: result.isPassed ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundStyle(result.isPassed ? .green : .red)
                            VStack(alignment: .leading) {
                                Text(result.testName).font(.subheadline.bold())
                                Text(result.message).font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Button("Run Full Validation Suite") {
                    viewModel.run()
                }
                .disabled(viewModel.isRunning)
                .frame(maxWidth: .infinity)
            }
        }
    }
}

struct ValidationResult: Identifiable {
    let id = UUID()
    let testName: String
    let message: String
    let isPassed: Bool
}

class SDKIntegrationValidatorViewModel: ObservableObject {
    @Published var results: [ValidationResult] = []
    @Published var isRunning = false

    @MainActor
    func run() {
        isRunning = true
        let sdk = ToolsKitSDK.shared
        let registry = SDKModuleRegistry.shared

        var checks: [ValidationResult] = []

        // 1. Initialization check
        checks.append(ValidationResult(
            testName: "Core Initialization",
            message: sdk.isInitialized ? "SDK is fully initialized" : "SDK is not yet initialized",
            isPassed: sdk.isInitialized
        ))

        // 2. Module check
        let activeCount = registry.activeModuleIDs.count
        let totalCount = registry.modules.count
        checks.append(ValidationResult(
            testName: "Module Integrity",
            message: "\(activeCount) / \(totalCount) modules active",
            isPassed: activeCount > 0 || totalCount == 0
        ))

        // 3. Storage check
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let storageOk = FileManager.default.isWritableFile(atPath: appSupport.path)
        checks.append(ValidationResult(
            testName: "Data Persistence",
            message: storageOk ? "Storage directory is writable" : "Storage directory access denied",
            isPassed: storageOk
        ))

        // 4. Security check
        let noSandbox = sdk.developer.noSandbox.isEnabled
        checks.append(ValidationResult(
            testName: "Policy Enforcement",
            message: noSandbox ? "Sandbox mode: BYPASSED (Caution)" : "Sandbox mode: ENFORCED",
            isPassed: !noSandbox
        ))

        results = checks
        isRunning = false
    }
}
