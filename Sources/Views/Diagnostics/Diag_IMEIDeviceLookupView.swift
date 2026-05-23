import SwiftUI

struct Diag_IMEIDeviceLookupView: View {
    @State private var imeiInput: String = ""
    @State private var isLoading = false
    @State private var result: [(String, String)]?
    @State private var lookupHistory: [(String, String, Date)] = []

    private let service = IMEICheckService.shared

    var body: some View {
        Form {
            Section("IMEI Device Lookup") {
                VStack(spacing: 8) {
                    Image(systemName: "iphone.gen3.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.blue)
                    Text("Full Device Specifications")
                        .font(.headline)
                    Text("Get complete device specifications, model details, and hardware info from IMEI via live API")
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
                    HStack {
                        Text("\(imeiInput.count)/15 digits")
                            .font(.caption)
                            .foregroundStyle(.green)
                        Spacer()
                        Text(valid ? "Valid" : "Invalid checksum")
                            .font(.caption)
                            .foregroundStyle(valid ? .green : .red)
                    }
                }

                Button {
                    performLookup()
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Image(systemName: "magnifyingglass.circle.fill")
                        }
                        Text("Lookup Device Info")
                    }
                }
                .disabled(imeiInput.count != 15 || isLoading)
            }

            if let result = result {
                Section("Device Specifications") {
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

            if !lookupHistory.isEmpty {
                Section("Lookup History") {
                    ForEach(lookupHistory, id: \.0) { entry in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.0).font(.caption.monospaced())
                                Text(entry.1).font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(entry.2, style: .time).font(.caption2).foregroundStyle(.tertiary)
                        }
                    }
                }
            }

            Section("Information Retrieved") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Brand, model, and device type", systemImage: "iphone")
                        .font(.caption)
                    Label("Display size and resolution", systemImage: "display")
                        .font(.caption)
                    Label("Chipset, RAM, and storage options", systemImage: "cpu")
                        .font(.caption)
                    Label("Camera specifications", systemImage: "camera.fill")
                        .font(.caption)
                    Label("Connectivity: NFC, Bluetooth, WiFi, bands", systemImage: "wifi")
                        .font(.caption)
                    Label("Battery capacity and dimensions", systemImage: "battery.100")
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Device Lookup")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func performLookup() {
        let imei = imeiInput.filter { $0.isNumber }
        guard imei.count == 15 else { return }
        isLoading = true

        Task {
            let apiResult = await service.lookupDeviceInfo(imei)

            await MainActor.run {
                isLoading = false
                result = apiResult.details
                let modelName = apiResult.details.first(where: { $0.0 == "Model" })?.1 ?? "Unknown"
                lookupHistory.insert((imei, modelName, Date()), at: 0)

                DiagnosticReportManager.shared.logIfEnabled(
                    toolName: "IMEI Device Lookup",
                    category: "System",
                    status: .info,
                    details: "IMEI \(imei): \(modelName)"
                )
            }
        }
    }
}
