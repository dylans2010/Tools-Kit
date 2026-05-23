import SwiftUI

struct Diag_BlacklistCheckView: View {
    @State private var imeiInput: String = ""
    @State private var isLoading = false
    @State private var checkResult: DisplayResult?
    @State private var checkHistory: [DisplayResult] = []
    @State private var batchIMEIs: String = ""
    @State private var showBatchMode = false
    @State private var batchResults: [DisplayResult] = []
    @State private var isBatchLoading = false

    private let service = IMEICheckService.shared

    struct DisplayResult: Identifiable {
        let id = UUID()
        let imei: String
        let status: DisplayStatus
        let details: [(String, String)]
        let timestamp: Date

        enum DisplayStatus: String {
            case clean = "Clean"
            case blacklisted = "Blacklisted"
            case error = "Error"
            case unknown = "Unknown"

            var color: Color {
                switch self {
                case .clean: return .green
                case .blacklisted: return .red
                case .error: return .orange
                case .unknown: return .secondary
                }
            }

            var icon: String {
                switch self {
                case .clean: return "checkmark.shield.fill"
                case .blacklisted: return "xmark.shield.fill"
                case .error: return "exclamationmark.triangle.fill"
                case .unknown: return "questionmark.circle.fill"
                }
            }
        }
    }

    var body: some View {
        Form {
            Section("IMEI Blacklist Check") {
                VStack(spacing: 8) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 44))
                        .foregroundStyle(.blue)
                    Text("GSMA Blacklist Lookup")
                        .font(.headline)
                    Text("Check if a device IMEI has been reported lost, stolen, or has unpaid bills via live API")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Single IMEI Check") {
                TextField("15-digit IMEI number", text: $imeiInput)
                    .keyboardType(.numberPad)
                    .autocorrectionDisabled()
                    .onChange(of: imeiInput) { _, newValue in
                        imeiInput = String(newValue.filter { $0.isNumber }.prefix(15))
                    }

                if !imeiInput.isEmpty {
                    HStack {
                        Text("\(imeiInput.count)/15 digits")
                            .font(.caption)
                            .foregroundStyle(imeiInput.count == 15 ? .green : .secondary)
                        Spacer()
                        if imeiInput.count == 15 {
                            let valid = service.luhnValidate(imeiInput)
                            Text(valid ? "Valid format" : "Invalid checksum")
                                .font(.caption)
                                .foregroundStyle(valid ? .green : .red)
                        }
                    }
                }

                Button {
                    performBlacklistCheck()
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Image(systemName: "magnifyingglass.circle.fill")
                        }
                        Text("Check Blacklist Status")
                    }
                }
                .disabled(imeiInput.count != 15 || isLoading)
            }

            if let result = checkResult {
                Section("Result") {
                    HStack(spacing: 12) {
                        Image(systemName: result.status.icon)
                            .font(.title)
                            .foregroundStyle(result.status.color)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.status.rawValue)
                                .font(.headline)
                                .foregroundStyle(result.status.color)
                            Text("IMEI: \(result.imei)")
                                .font(.caption.monospaced())
                        }
                    }
                    .padding(.vertical, 4)

                    ForEach(result.details, id: \.0) { detail in
                        LabeledContent(detail.0) {
                            Text(detail.1)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                    }
                }
            }

            Section {
                Toggle("Batch Mode", isOn: $showBatchMode)
            }

            if showBatchMode {
                Section("Batch IMEI Check") {
                    Text("Enter multiple IMEIs (one per line)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $batchIMEIs)
                        .frame(minHeight: 100)
                        .font(.caption.monospaced())

                    Button {
                        performBatchCheck()
                    } label: {
                        HStack {
                            if isBatchLoading {
                                ProgressView().scaleEffect(0.8)
                            } else {
                                Image(systemName: "list.bullet.clipboard")
                            }
                            Text("Check All IMEIs")
                        }
                    }
                    .disabled(batchIMEIs.isEmpty || isBatchLoading)
                }

                if !batchResults.isEmpty {
                    Section("Batch Results (\(batchResults.count))") {
                        ForEach(batchResults) { entry in
                            HStack {
                                Image(systemName: entry.status.icon)
                                    .foregroundStyle(entry.status.color)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.imei)
                                        .font(.caption.monospaced())
                                    Text(entry.status.rawValue)
                                        .font(.caption2)
                                        .foregroundStyle(entry.status.color)
                                }
                            }
                        }
                    }
                }
            }

            if !checkHistory.isEmpty {
                Section("Check History") {
                    ForEach(checkHistory) { entry in
                        HStack {
                            Image(systemName: entry.status.icon)
                                .foregroundStyle(entry.status.color)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.imei)
                                    .font(.caption.monospaced())
                                Text(entry.status.rawValue)
                                    .font(.caption2)
                                    .foregroundStyle(entry.status.color)
                            }
                            Spacer()
                            Text(entry.timestamp, style: .time)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("How Blacklisting Works") {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Carriers report lost/stolen devices to GSMA", systemImage: "1.circle.fill")
                        .font(.caption)
                    Label("IMEI is added to global blacklist database", systemImage: "2.circle.fill")
                        .font(.caption)
                    Label("Blacklisted devices cannot connect to networks", systemImage: "3.circle.fill")
                        .font(.caption)
                    Label("Unpaid device installments also trigger blacklisting", systemImage: "4.circle.fill")
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section("Manual Check Resources") {
                Link(destination: URL(string: "https://swappa.com/imei")!) {
                    Label("Swappa IMEI Check", systemImage: "safari.fill")
                        .font(.subheadline)
                }
                Link(destination: URL(string: "https://www.imeipro.info")!) {
                    Label("IMEIPro Lookup", systemImage: "safari.fill")
                        .font(.subheadline)
                }
                Link(destination: URL(string: "https://www.imei.info")!) {
                    Label("IMEI.info Database", systemImage: "safari.fill")
                        .font(.subheadline)
                }
            }
        }
        .navigationTitle("Blacklist Check")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func performBlacklistCheck() {
        let imei = imeiInput.filter { $0.isNumber }
        guard imei.count == 15 else { return }
        isLoading = true

        Task {
            let apiResult = await service.checkBlacklist(imei)

            await MainActor.run {
                isLoading = false

                let displayStatus: DisplayResult.DisplayStatus
                switch apiResult.status {
                case .clean: displayStatus = .clean
                case .blacklisted: displayStatus = .blacklisted
                case .error: displayStatus = .error
                case .unknown: displayStatus = .unknown
                }

                let result = DisplayResult(
                    imei: imei,
                    status: displayStatus,
                    details: apiResult.details,
                    timestamp: Date()
                )
                checkResult = result
                checkHistory.insert(result, at: 0)

                DiagnosticReportManager.shared.logIfEnabled(
                    toolName: "Blacklist Check",
                    category: "Security",
                    status: displayStatus == .clean ? .passed : displayStatus == .blacklisted ? .failed : .warning,
                    details: "IMEI \(imei): \(displayStatus.rawValue)"
                )
            }
        }
    }

    private func performBatchCheck() {
        let imeis = batchIMEIs
            .components(separatedBy: .newlines)
            .map { $0.filter { $0.isNumber } }
            .filter { $0.count == 15 }

        guard !imeis.isEmpty else { return }
        isBatchLoading = true
        batchResults = []

        Task {
            for imei in imeis {
                let apiResult = await service.checkBlacklist(imei)

                let displayStatus: DisplayResult.DisplayStatus
                switch apiResult.status {
                case .clean: displayStatus = .clean
                case .blacklisted: displayStatus = .blacklisted
                case .error: displayStatus = .error
                case .unknown: displayStatus = .unknown
                }

                let result = DisplayResult(
                    imei: imei,
                    status: displayStatus,
                    details: apiResult.details,
                    timestamp: Date()
                )

                await MainActor.run {
                    batchResults.append(result)
                }
            }

            await MainActor.run {
                isBatchLoading = false

                DiagnosticReportManager.shared.logIfEnabled(
                    toolName: "Blacklist Check",
                    category: "Security",
                    status: .info,
                    details: "Batch checked \(imeis.count) IMEIs"
                )
            }
        }
    }
}
