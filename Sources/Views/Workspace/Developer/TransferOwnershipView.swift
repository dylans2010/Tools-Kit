import SwiftUI

struct TransferOwnershipView: View {
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var selectedAppID: UUID?
    @State private var recipientEmail = ""
    @State private var confirmationName = ""
    @State private var isTransferring = false

    var selectedApp: DeveloperApp? {
        appService.apps.first { $0.id == selectedAppID }
    }

    var body: some View {
        Form {
            Section("Source Application") {
                Picker("App", selection: $selectedAppID) {
                    Text("Select an Application").tag(Optional<UUID>.none)
                    ForEach(appService.apps) { app in
                        Text(app.name).tag(Optional(app.id))
                    }
                }
            }

            Section("Target Recipient") {
                TextField("Recipient Email Address", text: $recipientEmail)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                Text("The recipient will receive an ownership invitation. They must have a verified developer account.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let app = selectedApp {
                Section("Critical Confirmation") {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Irreversible Action", systemImage: "exclamationmark.triangle.fill").font(.subheadline.bold()).foregroundStyle(.red)
                        Text("You will lose all administrative control over '\(app.name)'. All API keys, secrets, and deployment history will be moved to the new owner.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)

                    TextField("Type '\(app.name)' to confirm", text: $confirmationName)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }

                Section {
                    Button(role: .destructive) {
                        transfer()
                    } label: {
                        if isTransferring {
                            ProgressView().tint(.white).frame(maxWidth: .infinity)
                        } else {
                            Text("Execute Ownership Transfer")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(confirmationName != app.name || recipientEmail.isEmpty || isTransferring)
                }
            }
        }
        .navigationTitle("Transfer Ownership")
        .onAppear {
            if selectedAppID == nil { selectedAppID = appService.apps.first?.id }
        }
    }

    private func transfer() {
        guard let appID = selectedAppID else { return }
        isTransferring = true
        Task {
            try? await appService.transferOwnership(appID: appID, toEmail: recipientEmail)
            await MainActor.run {
                isTransferring = false
                recipientEmail = ""
                confirmationName = ""
            }
        }
    }
}
