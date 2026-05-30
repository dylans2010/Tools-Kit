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
                                        .foregroundStyle(result.passed ? .green : .red)
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

        Task {
            // Real validation logic
            let iconPassed = !app.iconName.isEmpty
            let bundlePassed = app.bundleId.contains(".") && app.bundleId.count > 5
            let descPassed = app.description.count >= 20
            let versionPassed = app.version.split(separator: ".").count >= 2
            let scopePassed = !app.grantedScopes.isEmpty

            await MainActor.run {
                results = [
                    ValidationResult(name: "Icon Asset", passed: iconPassed, message: iconPassed ? "Icon asset found." : "Missing app icon."),
                    ValidationResult(name: "Bundle Identifier", passed: bundlePassed, message: bundlePassed ? "Valid bundle identifier." : "Invalid or missing bundle identifier."),
                    ValidationResult(name: "Description", passed: descPassed, message: descPassed ? "Description is sufficient." : "Description too short (min 20 chars)."),
                    ValidationResult(name: "Version String", passed: versionPassed, message: versionPassed ? "Valid semantic version." : "Invalid version format."),
                    ValidationResult(name: "Granted Scopes", passed: scopePassed, message: scopePassed ? "Permissions configured." : "No permissions declared.")
                ]
                isValidating = false
            }
        }
    }
}
