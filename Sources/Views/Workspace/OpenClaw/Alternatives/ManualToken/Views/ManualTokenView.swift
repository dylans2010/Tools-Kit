import SwiftUI

struct ManualTokenView: View {
    @State private var viewModel = ManualTokenViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Manual Pairing Token", systemImage: "key.fill")
                        .font(.headline)
                    Text("Copy the long-lived pairing token from your Mac's OpenClaw settings and paste it here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }

            Section("Gateway Details") {
                TextField("IP Address or Hostname", text: $viewModel.host)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                TextField("Port", text: $viewModel.port)
                    .keyboardType(.numberPad)
            }

            Section("Pairing Token") {
                TextEditor(text: $viewModel.token)
                    .frame(height: 100)
                    .font(.system(.body, design: .monospaced))
            }

            if let error = viewModel.error {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }

            Section {
                Button {
                    Task {
                        await viewModel.pair()
                    }
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isValidating {
                            ProgressView()
                        } else {
                            Text("Validate & Pair")
                                .bold()
                        }
                        Spacer()
                    }
                }
                .disabled(viewModel.host.isEmpty || viewModel.token.isEmpty || viewModel.isValidating)
            }

            if viewModel.isSuccess {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.green)
                        Text("Secure Trust Established")
                            .font(.headline)
                        Button("Continue") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            }
        }
        .navigationTitle("Manual Token")
    }
}
