import SwiftUI

struct Diag_IMEINetworkCheckView: View {
    @State private var imeiInput: String = ""
    @State private var isLoading = false
    @State private var result: [(String, String)]?
    @State private var checkHistory: [(String, Date)] = []

    private let service = IMEICheckService.shared

    var body: some View {
        Form {
            Section("IMEI Network & Country Check") {
                VStack(spacing: 8) {
                    Image(systemName: "globe.americas.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.blue)
                    Text("Network & Country Lookup")
                        .font(.headline)
                    Text("Identify the original network, country, and registration details for any IMEI via live API")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Enter IMEI") {
                TextField("15-digit IMEI number", text: $imeiInput)
                    .keyboardType(.numberPad)
                    .autocorrectionDisabled()
                    .onChange(of: imeiInput) { _, newValue in
                        imeiInput = String(newValue.filter { $0.isNumber }.prefix(15))
                    }

                if !imeiInput.isEmpty && imeiInput.count == 15 {
                    let valid = service.luhnValidate(imeiInput)
                    Text(valid ? "Valid IMEI" : "Invalid checksum")
                        .font(.caption)
                        .foregroundStyle(valid ? .green : .red)
                }

                Button {
                    performCheck()
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                        }
                        Text("Lookup Network Info")
                    }
                }
                .disabled(imeiInput.count != 15 || isLoading)
            }

            if let result = result {
                Section("Network Information") {
                    ForEach(result, id: \.0) { detail in
                        LabeledContent(detail.0) {
                            Text(detail.1)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                    }
                }
            }

            if !checkHistory.isEmpty {
                Section("Lookup History") {
                    ForEach(checkHistory, id: \.0) { entry in
                        HStack {
                            Text(entry.0).font(.caption.monospaced())
                            Spacer()
                            Text(entry.1, style: .time).font(.caption2).foregroundStyle(.tertiary)
                        }
                    }
                }
            }

            Section("What This Checks") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Original carrier/network the device was sold to", systemImage: "antenna.radiowaves.left.and.right")
                        .font(.caption)
                    Label("Country of registration and sale", systemImage: "globe")
                        .font(.caption)
                    Label("SIM lock status and unlock eligibility", systemImage: "lock.fill")
                        .font(.caption)
                    Label("Device model and brand identification", systemImage: "iphone")
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Network Check")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func performCheck() {
        let imei = imeiInput.filter { $0.isNumber }
        guard imei.count == 15 else { return }
        isLoading = true

        Task {
            let apiResult = await service.checkNetwork(imei)

            await MainActor.run {
                isLoading = false
                result = apiResult.details
                checkHistory.insert((imei, Date()), at: 0)

                DiagnosticReportManager.shared.logIfEnabled(
                    toolName: "IMEI Network Check",
                    category: "Connectivity",
                    status: .info,
                    details: "Network lookup for IMEI \(imei)"
                )
            }
        }
    }
}
