import SwiftUI

struct Diag_IMEIBatchCheckerView: View {
    @State private var batchInput: String = ""
    @State private var isLoading = false
    @State private var results: [BatchResult] = []
    @State private var progress: Int = 0
    @State private var totalCount: Int = 0

    private let service = IMEICheckService.shared

    struct BatchResult: Identifiable {
        let id = UUID()
        let imei: String
        let isValid: Bool
        let blacklistStatus: String
        let model: String
        let details: [(String, String)]
    }

    var body: some View {
        Form {
            Section("Batch IMEI Checker") {
                VStack(spacing: 8) {
                    Image(systemName: "list.clipboard.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.blue)
                    Text("Bulk IMEI Processing")
                        .font(.headline)
                    Text("Check multiple IMEIs at once for blacklist, lock, and device info via live API")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Enter IMEIs (one per line)") {
                TextEditor(text: $batchInput)
                    .frame(minHeight: 120)
                    .font(.caption.monospaced())

                let imeis = parseIMEIs()
                Text("\(imeis.count) valid IMEIs detected")
                    .font(.caption)
                    .foregroundStyle(imeis.isEmpty ? .secondary : .green)

                Button {
                    runBatchCheck()
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView().scaleEffect(0.8)
                            Text("Checking \(progress)/\(totalCount)...")
                        } else {
                            Image(systemName: "play.circle.fill")
                            Text("Run Batch Check")
                        }
                    }
                }
                .disabled(imeis.isEmpty || isLoading)
            }

            if isLoading && totalCount > 0 {
                Section("Progress") {
                    ProgressView(value: Double(progress), total: Double(totalCount))
                    Text("\(progress) of \(totalCount) completed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !results.isEmpty {
                Section("Results (\(results.count))") {
                    let cleanCount = results.filter { $0.blacklistStatus.lowercased().contains("clean") || $0.blacklistStatus == "N/A" }.count
                    let flaggedCount = results.filter { $0.blacklistStatus.lowercased().contains("black") || $0.blacklistStatus.lowercased().contains("stolen") }.count

                    HStack(spacing: 16) {
                        VStack {
                            Text("\(results.count)").font(.title2.bold().monospacedDigit())
                            Text("Total").font(.caption2).foregroundStyle(.secondary)
                        }
                        VStack {
                            Text("\(cleanCount)").font(.title2.bold().monospacedDigit()).foregroundStyle(.green)
                            Text("Clean").font(.caption2).foregroundStyle(.secondary)
                        }
                        VStack {
                            Text("\(flaggedCount)").font(.title2.bold().monospacedDigit()).foregroundStyle(.red)
                            Text("Flagged").font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)

                    ForEach(results) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: entry.isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(entry.isValid ? .green : .red)
                                Text(entry.imei)
                                    .font(.caption.monospaced())
                                Spacer()
                                Text(entry.blacklistStatus)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(entry.blacklistStatus.lowercased().contains("clean") ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                            if !entry.model.isEmpty {
                                Text(entry.model)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }

                Section {
                    ShareLink(item: exportResults()) {
                        Label("Export Results", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
        .navigationTitle("Batch IMEI Checker")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func parseIMEIs() -> [String] {
        batchInput
            .components(separatedBy: .newlines)
            .map { $0.filter { $0.isNumber } }
            .filter { $0.count == 15 }
    }

    private func runBatchCheck() {
        let imeis = parseIMEIs()
        guard !imeis.isEmpty else { return }
        isLoading = true
        progress = 0
        totalCount = imeis.count
        results = []

        Task {
            for imei in imeis {
                let isValid = service.luhnValidate(imei)
                let apiResult = await service.checkBlacklist(imei)

                let model = apiResult.details.first(where: { $0.0 == "Model" })?.1 ?? ""
                let blacklistStatus = apiResult.details.first(where: { $0.0 == "Blacklist Status" })?.1 ?? apiResult.status.rawValue

                let entry = BatchResult(
                    imei: imei,
                    isValid: isValid,
                    blacklistStatus: blacklistStatus,
                    model: model,
                    details: apiResult.details
                )

                await MainActor.run {
                    results.append(entry)
                    progress += 1
                }
            }

            await MainActor.run {
                isLoading = false

                DiagnosticReportManager.shared.logIfEnabled(
                    toolName: "Batch IMEI Checker",
                    category: "Security",
                    status: .info,
                    details: "Batch checked \(imeis.count) IMEIs"
                )
            }
        }
    }

    private func exportResults() -> String {
        var text = "BATCH IMEI CHECK RESULTS\n"
        text += "========================\n"
        text += "Date: \(Date())\n"
        text += "Total: \(results.count)\n\n"
        for r in results {
            text += "IMEI: \(r.imei)\n"
            text += "Valid: \(r.isValid ? "Yes" : "No")\n"
            text += "Status: \(r.blacklistStatus)\n"
            if !r.model.isEmpty { text += "Model: \(r.model)\n" }
            text += "\n"
        }
        return text
    }
}
