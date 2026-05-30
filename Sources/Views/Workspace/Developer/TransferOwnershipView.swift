import SwiftUI

struct TransferOwnershipView: View {
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var selectedAppID: UUID?
    @State private var recipientAccountIDString = ""
    @State private var confirmationName = ""

    var selectedApp: DeveloperApp? {
        appService.apps.first { $0.id == selectedAppID }
    }

    var body: some View {
        Form {
            Section("Select Resource") {
                Picker("App to Transfer", selection: $selectedAppID) {
                    Text("Select an App").tag(Optional<UUID>.none)
                    ForEach(appService.apps) { app in
                        Text(app.name).tag(Optional(app.id))
                    }
                }
            }

            Section("Recipient Details") {
                TextField("Recipient Account ID", text: $recipientAccountIDString)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }

            if let app = selectedApp {
                Section("Confirmation") {
                    Text("This action is permanent. All ownership, settings, and keys will be transferred to the recipient.")
                        .font(.caption)
                        .foregroundStyle(.red)

                    TextField("Type '\(app.name)' to confirm", text: $confirmationName)
                        .autocapitalization(.none)
                }

                Section {
                    Button(role: .destructive) {
                        transfer()
                    } label: {
                        Text("Initiate Transfer")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(confirmationName != app.name || recipientAccountIDString.isEmpty)
                }
            }
        }
        .navigationTitle("Transfer Ownership")
    }

    private func transfer() {
        guard let appID = selectedAppID else { return }
        Task {
            try? await appService.transferOwnership(appID: appID, toEmail: recipientAccountIDString)
        }
    }
}
