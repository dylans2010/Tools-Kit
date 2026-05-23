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
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Area
                    VStack(spacing: 8) {
                        Image(systemName: "list.clipboard.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(Color.blue)
                        Text("Bulk IMEI Processing")
                            .font(.headline)
                        Text("Check multiple IMEIs at once for blacklist, lock, and device info via live API")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()

                    // Input Area
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Enter IMEIs (one per line)")
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            TextField("Paste IMEIs here...", text: $batchInput, axis: .vertical)
                                .padding()
                                .font(.caption.monospaced())
                                .lineLimit(6...12)

                            let imeis = parseIMEIs()
                            Text("\(imeis.count) valid IMEIs detected")
                                .font(.caption)
                                .foregroundStyle(imeis.isEmpty ? .secondary : Color.green)
                        }
                    }
                    .padding(.horizontal)

                    // Buttons Area
                    HStack(spacing: 12) {
                        Button {
                            runBatchCheck()
                        } label: {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                    Text("Checking \(progress)/\(totalCount)...")
                                } else {
                                    Image(systemName: "play.circle.fill")
                                    Text("Run Batch Check")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        }
                        .disabled(parseIMEIs().isEmpty || isLoading)

                        Button {
                            batchInput = ""
                            results = []
                            progress = 0
                            totalCount = 0
                        } label: {
                            Image(systemName: "trash")
                                .padding()
                                .foregroundStyle(Color.red)
                        }
                        .disabled(isLoading)
                    }
                    .padding(.horizontal)

                    // Progress Area
                    if isLoading && totalCount > 0 {
                        Section {
                            VStack(alignment: .leading, spacing: 4) {
                                ProgressView(value: Double(progress), total: Double(totalCount))
                                Text("\(progress) of \(totalCount) completed")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Results Area
                    if !results.isEmpty {
                        Section {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Results (\(results.count))")
                                    .font(.headline)

                                let cleanCount = results.filter { $0.blacklistStatus.lowercased().contains("clean") || $0.blacklistStatus == "N/A" }.count
                                let flaggedCount = results.filter { $0.blacklistStatus.lowercased().contains("black") || $0.blacklistStatus.lowercased().contains("stolen") }.count

                                HStack(spacing: 16) {
                                    VStack {
                                        Text("\(results.count)").font(.title2.bold().monospacedDigit())
                                        Text("Total").font(.caption2).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    VStack {
                                        Text("\(cleanCount)").font(.title2.bold().monospacedDigit()).foregroundStyle(Color.green)
                                        Text("Clean").font(.caption2).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    VStack {
                                        Text("\(flaggedCount)").font(.title2.bold().monospacedDigit()).foregroundStyle(Color.red)
                                        Text("Flagged").font(.caption2).foregroundStyle(.secondary)
                                    }
                                }
                                .padding()

                                ForEach(results) { entry in
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Image(systemName: entry.isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                                .foregroundStyle(entry.isValid ? Color.green : Color.red)
                                            Text(entry.imei)
                                                .font(.caption.monospaced())
                                            Spacer()
                                            Text(entry.blacklistStatus)
                                                .font(.caption2)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                        }
                                        if !entry.model.isEmpty {
                                            Text(entry.model)
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                        Divider()
                                    }
                                    .padding(.vertical, 4)
                                }

                                Button {
                                    // Fallback for ShareLink as it is not an allowed primitive
                                    let content = exportResults()
                                    print("Exported Content: \(content)")
                                } label: {
                                    Label("Export Results", systemImage: "square.and.arrow.up")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                }
                            }
                        }
                        .padding(.horizontal)
                    } else if !isLoading {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "tray")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text("No results yet")
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Batch IMEI Checker")
            .navigationBarTitleDisplayMode(.inline)
        }
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
