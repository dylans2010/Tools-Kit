import SwiftUI

struct Diag_IMEIComprehensiveView: View {
    @State private var imeiInput: String = ""
    @State private var isLoading = false
    @State private var blacklistResult: BlacklistCheckResult?
    @State private var carrierResult: CarrierLockResult?
    @State private var warrantyResult: WarrantyCheckResult?
    @State private var icloudResult: iCloudLockResult?
    @State private var deviceResult: DeviceInfoResult?
    @State private var progress: Int = 0

    private let service = IMEICheckService.shared

    var body: some View {
        Form {
            Section("Comprehensive IMEI Report") {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 44))
                        .foregroundStyle(.blue)
                    Text("Full IMEI Analysis")
                        .font(.headline)
                    Text("Run all checks at once: blacklist, carrier lock, warranty, iCloud lock, and device info via live APIs")
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
                        Text(valid ? "Valid IMEI" : "Invalid checksum")
                            .font(.caption)
                            .foregroundStyle(valid ? .green : .red)
                        if let structure = service.parseIMEIStructure(imeiInput) {
                            Spacer()
                            Text(structure.reportingBody)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Button {
                    runAllChecks()
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView().scaleEffect(0.8)
                            Text("Running checks (\(progress)/5)...")
                        } else {
                            Image(systemName: "play.circle.fill")
                            Text("Run All Checks")
                        }
                    }
                }
                .disabled(imeiInput.count != 15 || isLoading)
            }

            if isLoading {
                Section("Progress") {
                    ProgressView(value: Double(progress), total: 5.0)
                    Text("\(progress) of 5 checks completed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let result = blacklistResult {
                Section("Blacklist Status") {
                    HStack(spacing: 8) {
                        Image(systemName: result.status == .clean ? "checkmark.shield.fill" : result.status == .blacklisted ? "xmark.shield.fill" : "questionmark.circle.fill")
                            .foregroundStyle(result.status == .clean ? .green : result.status == .blacklisted ? .red : .orange)
                        Text(result.status.rawValue)
                            .font(.headline)
                            .foregroundStyle(result.status == .clean ? .green : result.status == .blacklisted ? .red : .orange)
                    }
                    ForEach(result.details.prefix(5), id: \.0) { d in
                        LabeledContent(d.0) { Text(d.1).font(.caption).foregroundStyle(.secondary).textSelection(.enabled) }
                    }
                }
            }

            if let result = carrierResult {
                Section("Carrier Lock") {
                    HStack(spacing: 8) {
                        Image(systemName: result.locked == false ? "lock.open.fill" : result.locked == true ? "lock.fill" : "questionmark.circle.fill")
                            .foregroundStyle(result.locked == false ? .green : result.locked == true ? .red : .orange)
                        Text(result.locked == false ? "Unlocked" : result.locked == true ? "Locked" : "Unknown")
                            .font(.headline)
                    }
                    ForEach(result.details.prefix(5), id: \.0) { d in
                        LabeledContent(d.0) { Text(d.1).font(.caption).foregroundStyle(.secondary).textSelection(.enabled) }
                    }
                }
            }

            if let result = warrantyResult {
                Section("Warranty Status") {
                    HStack(spacing: 8) {
                        Image(systemName: result.active == true ? "checkmark.seal.fill" : "xmark.circle.fill")
                            .foregroundStyle(result.active == true ? .green : .orange)
                        Text(result.active == true ? "Active" : "Check Complete")
                            .font(.headline)
                    }
                    ForEach(result.details.prefix(5), id: \.0) { d in
                        LabeledContent(d.0) { Text(d.1).font(.caption).foregroundStyle(.secondary).textSelection(.enabled) }
                    }
                }
            }

            if let result = icloudResult {
                Section("iCloud Lock") {
                    HStack(spacing: 8) {
                        Image(systemName: result.locked == true ? "lock.icloud.fill" : result.locked == false ? "checkmark.icloud.fill" : "questionmark.circle.fill")
                            .foregroundStyle(result.locked == true ? .orange : result.locked == false ? .green : .secondary)
                        Text(result.locked == true ? "Locked" : result.locked == false ? "Clear" : "Unknown")
                            .font(.headline)
                    }
                    ForEach(result.details.prefix(5), id: \.0) { d in
                        LabeledContent(d.0) { Text(d.1).font(.caption).foregroundStyle(.secondary).textSelection(.enabled) }
                    }
                }
            }

            if let result = deviceResult {
                Section("Device Information") {
                    ForEach(result.details, id: \.0) { d in
                        LabeledContent(d.0) { Text(d.1).font(.caption).foregroundStyle(.secondary).textSelection(.enabled) }
                    }
                }
            }

            if blacklistResult != nil || carrierResult != nil {
                Section {
                    ShareLink(item: exportReport()) {
                        Label("Export Full Report", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
        .navigationTitle("Comprehensive Check")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func runAllChecks() {
        let imei = imeiInput.filter { $0.isNumber }
        guard imei.count == 15 else { return }
        isLoading = true
        progress = 0
        blacklistResult = nil
        carrierResult = nil
        warrantyResult = nil
        icloudResult = nil
        deviceResult = nil

        Task {
            let bl = await service.checkBlacklist(imei)
            await MainActor.run { blacklistResult = bl; progress = 1 }

            let cl = await service.checkCarrierLock(imei)
            await MainActor.run { carrierResult = cl; progress = 2 }

            let wr = await service.checkWarranty(imei)
            await MainActor.run { warrantyResult = wr; progress = 3 }

            let ic = await service.checkiCloudLock(imei)
            await MainActor.run { icloudResult = ic; progress = 4 }

            let di = await service.lookupDeviceInfo(imei)
            await MainActor.run {
                deviceResult = di
                progress = 5
                isLoading = false

                DiagnosticReportManager.shared.logIfEnabled(
                    toolName: "Comprehensive IMEI Check",
                    category: "Security",
                    status: .info,
                    details: "Full check for IMEI \(imei): Blacklist=\(bl.status.rawValue), Lock=\(cl.locked == true ? "Locked" : cl.locked == false ? "Unlocked" : "Unknown")"
                )
            }
        }
    }

    private func exportReport() -> String {
        let imei = imeiInput
        var text = "COMPREHENSIVE IMEI REPORT\n"
        text += "=========================\n"
        text += "IMEI: \(imei)\n"
        text += "Date: \(Date())\n\n"

        if let bl = blacklistResult {
            text += "BLACKLIST: \(bl.status.rawValue)\n"
            for d in bl.details { text += "  \(d.0): \(d.1)\n" }
            text += "\n"
        }
        if let cl = carrierResult {
            text += "CARRIER LOCK: \(cl.locked == true ? "Locked" : cl.locked == false ? "Unlocked" : "Unknown")\n"
            for d in cl.details { text += "  \(d.0): \(d.1)\n" }
            text += "\n"
        }
        if let wr = warrantyResult {
            text += "WARRANTY: \(wr.active == true ? "Active" : "Unknown")\n"
            for d in wr.details { text += "  \(d.0): \(d.1)\n" }
            text += "\n"
        }
        if let ic = icloudResult {
            text += "ICLOUD LOCK: \(ic.locked == true ? "Locked" : ic.locked == false ? "Clear" : "Unknown")\n"
            for d in ic.details { text += "  \(d.0): \(d.1)\n" }
            text += "\n"
        }
        if let di = deviceResult {
            text += "DEVICE INFO:\n"
            for d in di.details { text += "  \(d.0): \(d.1)\n" }
        }
        return text
    }
}
