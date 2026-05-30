import SwiftUI

struct AppBundleValidatorView: View {
    let appID: UUID
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var isValidating = false
    @State private var results: [ValidationResult] = []

    struct ValidationResult: Identifiable {
        let id = UUID()
        let name: String
        let passed: Bool
        let message: String
    }

    var app: DeveloperApp? {
        appService.apps.first { $0.id == appID }
    }

    var body: some View {
        VStack {
            if let app = app {
                List {
                    Section {
                        HStack {
                            Text("App Bundle")
                            Spacer()
                            Text(app.bundleId).bold()
                        }
                    }

                    Section("Validation Results") {
                        if results.isEmpty && !isValidating {
                            Text("Ready to run pre-submission validation.").foregroundStyle(.secondary)
                        } else if isValidating {
                            HStack {
                                ProgressView()
                                Text("Running checks...")
                            }
                        } else {
                            ForEach(results) { result in
                                HStack {
                                    Image(systemName: result.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundStyle(result.passed ? .sdkSuccess : .sdkError)
                                    VStack(alignment: .leading) {
                                        Text(result.name).font(.subheadline.bold())
                                        Text(result.message).font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }

                Button("Run Validation") {
                    runValidation(for: app)
                }
                .buttonStyle(.borderedProminent)
                .padding()
                .disabled(isValidating)
            }
        }
        .navigationTitle("Bundle Validator")
    }

    private func runValidation(for app: DeveloperApp) {
        isValidating = true
        results = []

        // In a real application, this would perform actual file system and manifest analysis.
        // For this management suite, we perform logical consistency checks against the persistent state.
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)

            await MainActor.run {
                results = [
                    ValidationResult(name: "Icon Asset", passed: !app.iconName.isEmpty, message: app.iconName.isEmpty ? "Missing app icon." : "Icon asset found: \(app.iconName)"),
                    ValidationResult(name: "Bundle Identifier", passed: app.bundleId.contains("."), message: app.bundleId.contains(".") ? "Valid bundle identifier format." : "Invalid bundle identifier format."),
                    ValidationResult(name: "Version String", passed: !app.version.isEmpty, message: "Current version: \(app.version)"),
                    ValidationResult(name: "Description", passed: app.description.count > 10, message: app.description.count <= 10 ? "Description too short." : "Description is sufficient."),
                    ValidationResult(name: "Granted Scopes", passed: !app.grantedScopes.isEmpty, message: app.grantedScopes.isEmpty ? "No permissions declared." : "\(app.grantedScopes.count) permissions configured.")
                ]
                isValidating = false
            }
        }
    }
}
