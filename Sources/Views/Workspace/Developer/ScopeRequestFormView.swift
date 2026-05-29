import SwiftUI

struct ScopeRequestFormView: View {
    let scopeID: String
    @Environment(\.dismiss) var dismiss
    @ObservedObject var scopeService = DeveloperScopeService.shared
    @ObservedObject var appService = DeveloperAppService.shared

    @State private var selectedAppID: UUID?
    @State private var justification = ""
    @State private var useCase = ""
    @State private var volume = ""
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Target Resource") {
                    Picker("App", selection: $selectedAppID) {
                        Text("Select App").tag(Optional<UUID>.none)
                        ForEach(appService.apps) { app in
                            Text(app.name).tag(Optional(app.id))
                        }
                    }
                }

                Section("Justification") {
                    VStack(alignment: .leading) {
                        Text("Why do you need this scope?").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $justification)
                            .frame(height: 100)
                    }
                }

                Section("Usage Details") {
                    TextField("Expected API Volume", text: $volume)
                    VStack(alignment: .leading) {
                        Text("Usage Scenario").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $useCase)
                            .frame(height: 100)
                    }
                }
            }
            .navigationTitle("Request Scope")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") { submit() }
                        .disabled(selectedAppID == nil || justification.isEmpty)
                }
            }
            .disabled(isSubmitting)
        }
    }

    private func submit() {
        guard let appID = selectedAppID else { return }
        isSubmitting = true
        let request = ScopeRequest(
            appId: appID,
            scopeIdentifier: scopeID,
            justification: justification,
            useCaseDescription: useCase,
            expectedVolume: volume
        )
        Task {
            try? await scopeService.submitRequest(request)
            await MainActor.run {
                isSubmitting = false
                dismiss()
            }
        }
    }
}
