import SwiftUI

struct LMLinkAccountView: View {
    @State private var viewModel = LMLinkViewModel()

    var body: some View {
        List {
            Section(header: Text("Account")) {
                HStack {
                    Image(systemName: "person.crop.circle.fill")
                        .foregroundColor(isLinked ? .blue : .secondary)
                    VStack(alignment: .leading) {
                        Text(viewModel.statusTitle)
                            .font(.headline)
                        Text(viewModel.statusSubtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section(header: Text("Connection Status")) {
                HStack {
                    Text("Status")
                    Spacer()
                    if isLinked {
                        Label("Linked", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else if case .error = viewModel.authState {
                        Label("Error", systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                    } else if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Label("Not Linked", systemImage: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }

                if case .connected(let session) = viewModel.authState {
                    LabeledContent("Key ID", value: String(session.keyId.prefix(8)) + "...")
                    LabeledContent("User ID", value: session.userId)
                }
            }

            Section {
                if isLinked {
                    Button(role: .destructive, action: {
                        viewModel.disconnect()
                    }) {
                        Text("Unlink Device")
                    }
                } else {
                    Button(action: {
                        viewModel.signIn()
                    }) {
                        if viewModel.isLoading {
                            Text("Connecting...")
                        } else {
                            Text("Link LM Studio")
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
            }

            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                }
            }

            Section(header: Text("About LM Link")) {
                Text("LM Link uses cryptographic signatures to securely identify your device to local LM Studio instances on your network.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Account")
        .accessibilityElement(children: .contain)
        .accessibilityLabel("LM Link Account Settings")
    }

    private var isLinked: Bool {
        if case .connected = viewModel.authState { return true }
        return false
    }
}
