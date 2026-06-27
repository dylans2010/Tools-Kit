import SwiftUI

struct PairingCodeView: View {
    @State private var viewModel = PairingCodeViewModel()
    @Environment(\.dismiss) var dismiss

    // For simplicity in this demo, we use a fixed gateway or let user enter it
    @State private var gatewayHost: String = ""

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Label("One-Time Pairing Code", systemImage: "number.square")
                        .font(.headline)
                    Text("A 6-digit code is displayed on your Mac's OpenClaw dashboard. Enter it here to pair.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }

            Section("Gateway Address") {
                TextField("e.g. 192.168.1.5", text: $gatewayHost)
                    .keyboardType(.numbersAndPunctuation)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }

            Section("Enter Code") {
                TextField("6-digit code", text: $viewModel.code)
                    .keyboardType(.numberPad)
                    .font(.system(.title, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .onChange(of: viewModel.code) { oldValue, newValue in
                        if newValue.count > 6 {
                            viewModel.code = String(newValue.prefix(6))
                        }
                    }
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
                        if let url = URL(string: "ws://\(gatewayHost):18789") {
                            await viewModel.validate(gatewayURL: url)
                        }
                    }
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isValidating {
                            ProgressView()
                        } else {
                            Text("Pair Device")
                                .bold()
                        }
                        Spacer()
                    }
                }
                .disabled(viewModel.code.count < 6 || viewModel.isValidating || gatewayHost.isEmpty)
            }

            if viewModel.successToken != nil {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.green)
                        Text("Device Paired Successfully")
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
        .navigationTitle("Pairing Code")
    }
}
