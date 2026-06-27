import SwiftUI

struct LocalApprovalView: View {
    @State private var viewModel = LocalApprovalViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Local Approval", systemImage: "person.badge.shield.checkmark")
                        .font(.headline)
                    Text("Select your Mac. It will immediately show an incoming connection request with your iPhone's name and IP. Simply click 'Allow' on the Mac to pair.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }

            Section("Select Mac") {
                if viewModel.discoveredServices.isEmpty {
                    Text("Searching for gateways...")
                        .foregroundStyle(.secondary)
                        .italic()
                } else {
                    ForEach(viewModel.discoveredServices) { service in
                        Button {
                            Task {
                                await viewModel.requestApproval(from: service)
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(service.name)
                                        .font(.body.bold())
                                    Text(service.host)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if viewModel.isWaiting {
                                    ProgressView()
                                } else {
                                    Image(systemName: "hand.tap")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
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
                HStack {
                    Text("Status:")
                        .font(.subheadline.bold())
                    Text(viewModel.status)
                        .font(.subheadline)
                        .foregroundStyle(viewModel.status == "Approved!" ? .green : .blue)
                    Spacer()
                    if viewModel.status == "Approved!" {
                        Button("Done") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
        .navigationTitle("Local Approval")
        .onAppear {
            viewModel.startDiscovery()
        }
    }
}
