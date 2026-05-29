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

        // Simulate validation logic
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            results = [
                ValidationResult(name: "Icon Asset", passed: !app.iconName.isEmpty, message: app.iconName.isEmpty ? "Missing app icon." : "Icon asset found."),
                ValidationResult(name: "Bundle Identifier", passed: !app.bundleId.isEmpty, message: app.bundleId.isEmpty ? "Missing bundle identifier." : "Valid bundle identifier."),
                ValidationResult(name: "Description", passed: app.description.count > 10, message: app.description.count <= 10 ? "Description too short." : "Description is sufficient."),
                ValidationResult(name: "Granted Scopes", passed: !app.grantedScopes.isEmpty, message: app.grantedScopes.isEmpty ? "No permissions declared." : "Permissions configured.")
            ]
            isValidating = false
        }
    }
}
