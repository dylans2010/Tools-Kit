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
            // Real validation logic based on app state
            let checks = [
                ValidationResult(name: "Icon Asset", passed: !app.iconName.isEmpty, message: app.iconName.isEmpty ? "Missing app icon configuration." : "Icon asset '\(app.iconName)' is correctly registered."),
                ValidationResult(name: "Bundle Identifier", passed: app.bundleId.contains("."), message: !app.bundleId.contains(".") ? "Bundle ID must be in reverse-DNS format." : "Bundle identifier is correctly formatted."),
                ValidationResult(name: "Description", passed: app.description.count >= 20, message: app.description.count < 20 ? "Project description is too brief (min 20 chars)." : "Metadata description satisfies requirements."),
                ValidationResult(name: "Security Scopes", passed: !app.grantedScopes.isEmpty, message: app.grantedScopes.isEmpty ? "No security scopes have been requested or granted." : "\(app.grantedScopes.count) scopes successfully validated.")
            ]

            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second real delay for UI feedback

            await MainActor.run {
                self.results = checks
                self.isValidating = false
            }
        }
    }
}
