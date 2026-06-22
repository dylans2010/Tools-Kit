import SwiftUI
import CoreTelephony

struct Diag_CarrierLockView: View {
    @State private var lockStatus: LockStatus = .unknown
    @State private var checks: [(String, String, Bool)] = []
    @State private var carrierDetails: [(String, String)] = []
    @State private var imeiInput: String = ""
    @State private var isCheckingIMEI = false
    @State private var imeiResult: [(String, String)]?
    @State private var imeiLockStatus: LockStatus = .unknown
    @State private var checkHistory: [(String, LockStatus, Date)] = []

    private let service = IMEICheckService.shared

    enum LockStatus {
        case locked, unlocked, unknown

        var color: Color {
            switch self {
            case .locked: return .red
            case .unlocked: return .green
            case .unknown: return .secondary
            }
        }

        var icon: String {
            switch self {
            case .locked: return "lock.fill"
            case .unlocked: return "lock.open.fill"
            case .unknown: return "questionmark.circle.fill"
            }
        }

        var title: String {
            switch self {
            case .locked: return "Carrier Locked"
            case .unlocked: return "Unlocked"
            case .unknown: return "Unknown"
            }
        }
    }

    var body: some View {
        List {
            Section("Carrier Lock Status") {
                VStack(spacing: 12) {
                    Image(systemName: lockStatus.icon)
                        .font(.system(size: 52))
                        .foregroundStyle(lockStatus.color)
                    Text(lockStatus.title)
                        .font(.headline)
                    Text(lockStatusDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("SIM & Carrier Detection") {
                ForEach(checks, id: \.0) { check in
                    HStack {
                        Image(systemName: check.2 ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(check.2 ? .green : .red)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(check.0)
                                .font(.subheadline.weight(.medium))
                            Text(check.1)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if !carrierDetails.isEmpty {
                Section("Carrier Information") {
                    ForEach(carrierDetails, id: \.0) { detail in
                        LabeledContent(detail.0) {
                            Text(detail.1)
                                .font(.caption)
                                .textSelection(.enabled)
                        }
                    }
                }
            }

            Section("IMEI Carrier Lock Check") {
                TextField("Enter IMEI (15 digits)", text: $imeiInput)
                    .keyboardType(.numberPad)
                    .autocorrectionDisabled()
                    .onChange(of: imeiInput) { _, newValue in
                        imeiInput = String(newValue.filter { $0.isNumber }.prefix(15))
                    }

                if !imeiInput.isEmpty && imeiInput.count == 15 {
                    let valid = service.luhnValidate(imeiInput)
                    HStack {
                        Text(valid ? "Valid IMEI format" : "Invalid checksum")
                            .font(.caption)
                            .foregroundStyle(valid ? .green : .red)
                        Spacer()
                    }
                }

                Button {
                    checkIMEILock()
                } label: {
                    HStack {
                        if isCheckingIMEI {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                        }
                        Text("Check Lock via API")
                    }
                }
                .disabled(imeiInput.count != 15 || isCheckingIMEI)

                if let results = imeiResult {
                    VStack(spacing: 0) {
                        HStack(spacing: 12) {
                            Image(systemName: imeiLockStatus.icon)
                                .font(.title2)
                                .foregroundStyle(imeiLockStatus.color)
                            Text(imeiLockStatus.title)
                                .font(.headline)
                                .foregroundStyle(imeiLockStatus.color)
                        }
                        .padding(.vertical, 8)

                        ForEach(results, id: \.0) { r in
                            LabeledContent(r.0) {
                                Text(r.1)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                }
            }

            if !checkHistory.isEmpty {
                Section("Check History") {
                    ForEach(checkHistory, id: \.0) { entry in
                        HStack {
                            Image(systemName: entry.1.icon)
                                .foregroundStyle(entry.1.color)
                            Text(entry.0)
                                .font(.caption.monospaced())
                            Spacer()
                            Text(entry.1.title)
                                .font(.caption2)
                                .foregroundStyle(entry.1.color)
                            Text(entry.2, style: .time)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }

            Section("Understanding Carrier Locks") {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Locked: Device only works with original carrier's SIM", systemImage: "lock.fill")
                        .font(.caption)
                    Label("Unlocked: Device works with any compatible carrier", systemImage: "lock.open.fill")
                        .font(.caption)
                    Label("Factory Unlocked: Never locked to any carrier", systemImage: "lock.open.rotation")
                        .font(.caption)
                    Label("Contact carrier or use IMEI to verify unlock eligibility", systemImage: "phone.fill")
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section("Unlock Resources") {
                Link(destination: URL(string: "https://www.att.com/deviceunlock/")!) {
                    Label("AT&T Device Unlock", systemImage: "safari.fill").font(.subheadline)
                }
                Link(destination: URL(string: "https://www.t-mobile.com/support/account/unlock-your-mobile-wireless-device")!) {
                    Label("T-Mobile Unlock", systemImage: "safari.fill").font(.subheadline)
                }
                Link(destination: URL(string: "https://www.verizon.com/support/device-locking-background/")!) {
                    Label("Verizon Unlock Policy", systemImage: "safari.fill").font(.subheadline)
                }
            }

            Section {
                Button {
                    detectLockStatus()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Re-detect")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Carrier Lock")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { detectLockStatus() }
    }

    private var lockStatusDescription: String {
        switch lockStatus {
        case .locked: return "This device appears to be locked to a specific carrier"
        case .unlocked: return "This device appears to accept any carrier SIM"
        case .unknown: return "Unable to definitively determine lock status from local detection"
        }
    }

    private func detectLockStatus() {
        var results: [(String, Bool)] = []
        var details: [(String, String)] = []
        let info = CTTelephonyNetworkInfo()

        if let providers = info.serviceSubscriberCellularProviders {
            let hasCarrier = providers.values.contains { $0.carrierName != nil }
            results.append(("SIM Detected", hasCarrier))

            for (slot, carrier) in providers {
                if let name = carrier.carrierName {
                    details.append(("Carrier (\(slot))", name))
                }
                if let mcc = carrier.mobileCountryCode {
                    details.append(("MCC (\(slot))", mcc))
                }
                if let mnc = carrier.mobileNetworkCode {
                    details.append(("MNC (\(slot))", mnc))
                }
                if let iso = carrier.isoCountryCode {
                    details.append(("Country (\(slot))", iso.uppercased()))
                }
                details.append(("VoIP (\(slot))", carrier.allowsVOIP ? "Yes" : "No"))
            }

            let multiSIM = providers.count > 1
            details.append(("Dual SIM", multiSIM ? "Yes (\(providers.count) slots)" : "Single SIM"))
        }

        if let radioTechs = info.serviceCurrentRadioAccessTechnology {
            let connected = !radioTechs.isEmpty
            results.append(("Cellular Connected", connected))
            for (slot, tech) in radioTechs {
                let techName = friendlyRadioName(tech)
                details.append(("Radio (\(slot))", techName))
            }
        }

        let hasDataCapability = info.serviceSubscriberCellularProviders?.values.contains { $0.mobileCountryCode != nil } ?? false
        results.append(("Data Capability", hasDataCapability))

        checks = results.map { ($0.0, $0.1 ? "Available" : "Not available", $0.1) }
        carrierDetails = details

        let passCount = results.filter { $0.1 }.count
        if passCount == results.count {
            lockStatus = .unlocked
        } else if passCount == 0 {
            lockStatus = .unknown
        } else {
            lockStatus = .unknown
        }

        DiagnosticReportManager.shared.logIfEnabled(
            toolName: "Carrier Lock",
            category: "Connectivity",
            status: lockStatus == .unlocked ? .passed : lockStatus == .locked ? .failed : .info,
            details: "Local detection: \(lockStatus.title)"
        )
    }

    private func friendlyRadioName(_ tech: String) -> String {
        if tech.contains("NR") { return "5G NR" }
        if tech.contains("LTE") { return "4G LTE" }
        if tech.contains("WCDMA") { return "3G WCDMA" }
        if tech.contains("HSDPA") { return "3G HSDPA" }
        if tech.contains("EDGE") { return "2G EDGE" }
        if tech.contains("GPRS") { return "2G GPRS" }
        return tech
    }

    private func checkIMEILock() {
        let imei = imeiInput.filter { $0.isNumber }
        guard imei.count == 15 else { return }
        isCheckingIMEI = true

        Task {
            let apiResult = await service.checkCarrierLock(imei)

            await MainActor.run {
                isCheckingIMEI = false
                imeiResult = apiResult.details

                if let locked = apiResult.locked {
                    imeiLockStatus = locked ? .locked : .unlocked
                } else {
                    imeiLockStatus = .unknown
                }

                checkHistory.insert((imei, imeiLockStatus, Date()), at: 0)

                DiagnosticReportManager.shared.logIfEnabled(
                    toolName: "Carrier Lock",
                    category: "Connectivity",
                    status: imeiLockStatus == .unlocked ? .passed : imeiLockStatus == .locked ? .failed : .warning,
                    details: "IMEI \(imei): \(imeiLockStatus.title)"
                )
            }
        }
    }
}
