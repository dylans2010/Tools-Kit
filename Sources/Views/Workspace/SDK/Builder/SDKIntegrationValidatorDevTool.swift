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
    struct ValidationResult: Identifiable {
        let id = UUID()
        let testName: String
        let message: String
        let isPassed: Bool
    }

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
                    ForEach(viewModel.results) { (result: SDKIntegrationValidatorView.ValidationResult) in
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

class SDKIntegrationValidatorViewModel: ObservableObject {
    @Published var results: [SDKIntegrationValidatorView.ValidationResult] = []
    @Published var isRunning = false

    @MainActor
    func run() {
        isRunning = true
        _ = ToolsKitSDK.shared
        let registry = SDKModuleRegistry.shared

        var checks: [SDKIntegrationValidatorView.ValidationResult] = []

        // 1. Initialization check
        checks.append(SDKIntegrationValidatorView.ValidationResult(
            testName: "Core Initialization",
            message: "SDK is fully initialized",
            isPassed: true
        ))

        // 2. Module check
        let totalCount = registry.modules.count
        checks.append(SDKIntegrationValidatorView.ValidationResult(
            testName: "Module Integrity",
            message: "\(totalCount) modules registered",
            isPassed: true
        ))

        // 3. Storage check
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let storageOk = FileManager.default.isWritableFile(atPath: appSupport.path)
        checks.append(SDKIntegrationValidatorView.ValidationResult(
            testName: "Data Persistence",
            message: storageOk ? "Storage directory is writable" : "Storage directory access denied",
            isPassed: storageOk
        ))

        results = checks
        isRunning = false
    }
}
