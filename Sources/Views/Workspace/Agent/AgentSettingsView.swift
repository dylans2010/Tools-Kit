import SwiftUI

struct AgentSettingsView: View {
    @State private var apiKey: String = ""
    @State private var isValidating = false
    @State private var validationError: String?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Jules API Key")) {
                    SecureField("Enter API Key", text: $apiKey)

                    if let error = validationError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }

                    Link("Get your API key", destination: URL(string: "https://jules.google/settings/api")!)
                        .font(.caption)
                }

                Section {
                    Button(action: validateAndSave) {
                        if isValidating {
                            ProgressView()
                        } else {
                            Text("Save and Validate")
                        }
                    }
                    .disabled(apiKey.isEmpty || isValidating)

                    Button("Remove Key", role: .destructive) {
                        AgentKeychainManager.shared.deleteKey()
                        apiKey = ""
                        dismiss()
                    }
                }
            }
            .navigationTitle("Agent Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                apiKey = AgentKeychainManager.shared.getKey() ?? ""
            }
        }
    }

    private func validateAndSave() {
        isValidating = true
        validationError = nil

        // Temporarily save to validate
        let _ = AgentKeychainManager.shared.saveKey(apiKey)

        Task {
            do {
                let isValid = try await AgentClient.shared.validateKey()
                await MainActor.run {
                    if isValid {
                        dismiss()
                    } else {
                        validationError = "Invalid API key. Please try again."
                        isValidating = false
                    }
                }
            } catch {
                await MainActor.run {
                    validationError = AgentErrorHandler.handle(error)
                    isValidating = false
                }
            }
        }
    }
}
