import SwiftUI

struct ManualDeviceAddView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var discoveryService: LMDeviceDiscoveryService

    @State private var ip: String = ""
    @State private var port: String = "1234"
    @State private var isAdding = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Device Details")) {
                    TextField("IP Address (e.g., 192.168.1.5)", text: $ip)
                        .keyboardType(.decimalPad)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    TextField("Port (default: 1234)", text: $port)
                        .keyboardType(.numberPad)
                }

                Section {
                    Button(action: addDevice) {
                        if isAdding {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Add Device")
                                .bold()
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(ip.isEmpty || port.isEmpty || isAdding)
                }
            }
            .navigationTitle("Add Device")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func addDevice() {
        guard let portInt = Int(port) else { return }
        isAdding = true

        Task {
            await discoveryService.manualAddDevice(ip: ip, port: portInt)
            await MainActor.run {
                isAdding = false
                dismiss()
            }
        }
    }
}
