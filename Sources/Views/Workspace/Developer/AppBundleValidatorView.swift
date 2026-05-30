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
            try? await Task.sleep(nanoseconds: 1_000_000_000)

            let bundleIdRegex = "^[a-zA-Z0-9.-]+$"
            let isBundleIdValid = app.bundleId.range(of: bundleIdRegex, options: .regularExpression) != nil

            let validationResults = [
                ValidationResult(name: "Icon Asset", passed: !app.iconName.isEmpty, message: app.iconName.isEmpty ? "Missing app icon." : "Icon asset found."),
                ValidationResult(name: "Bundle Identifier", passed: isBundleIdValid && !app.bundleId.isEmpty, message: app.bundleId.isEmpty ? "Missing bundle identifier." : (isBundleIdValid ? "Valid bundle identifier format." : "Invalid characters in bundle ID.")),
                ValidationResult(name: "Description", passed: app.description.count > 10, message: app.description.count <= 10 ? "Description too short (min 10 chars)." : "Description is sufficient."),
                ValidationResult(name: "Granted Scopes", passed: !app.grantedScopes.isEmpty, message: app.grantedScopes.isEmpty ? "No permissions declared." : "\(app.grantedScopes.count) permissions configured."),
                ValidationResult(name: "Version Format", passed: app.version.split(separator: ".").count >= 2, message: "Current version: \(app.version)"),
                ValidationResult(name: "Platform Targets", passed: !app.platformTargets.isEmpty, message: app.platformTargets.isEmpty ? "No platforms selected." : "Targeting \(app.platformTargets.count) platforms.")
            ]

            await MainActor.run {
                results = validationResults
                isValidating = false
            }
        }
    }
}
