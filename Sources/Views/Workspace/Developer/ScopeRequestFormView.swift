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
                Section("Request Context") {
                    Picker("Target App", selection: $selectedAppID) {
                        Text("Account Level").tag(Optional<UUID>.none)
                        ForEach(appService.apps) { app in
                            Text(app.name).tag(Optional(app.id))
                        }
                    }

                    LabeledContent("Scope", value: scopeID)
                }

                Section("Justification") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Why does this application require this specific permission?").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $justification)
                            .frame(minHeight: 100)
                    }
                }

                Section("Implementation Details") {
                    TextField("Estimated API Request Volume", text: $volume)
                        .keyboardType(.numberPad)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Usage Scenario").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $useCase)
                            .frame(minHeight: 100)
                    }
                }
            }
            .navigationTitle("Request Permission")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") { submit() }
                        .disabled(justification.count < 10)
                }
            }
            .disabled(isSubmitting)
        }
    }

    private func submit() {
        isSubmitting = true
        let request = ScopeRequest(
            appId: selectedAppID ?? UUID(),
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
