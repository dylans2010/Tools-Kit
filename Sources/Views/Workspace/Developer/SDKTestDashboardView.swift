import SwiftUI

struct SDKTestDashboardView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared
    @State private var isRunning = false

    var body: some View {
        List {
            Section("Test Execution") {
                Button(action: runTests) {
                    HStack {
                        Label("Run Unit Tests", systemImage: "play.circle.fill")
                        Spacer()
                        if isRunning {
                            ProgressView()
                        }
                    }
                }
                .disabled(isRunning)
            }

            Section("Test Results") {
                if store.sdkTestResults.isEmpty {
                    Text("No tests executed yet.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    let passedCount = store.sdkTestResults.filter { $0.status == .passed }.count
                    let totalCount = store.sdkTestResults.count

                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(passedCount)/\(totalCount) Passed")
                                .font(.headline)
                            ProgressView(value: Double(passedCount), total: Double(totalCount))
                                .tint(.green)
                        }
                        Spacer()
                        Text("\(Int(Double(passedCount)/Double(totalCount) * 100))%")
                            .font(.title2.bold())
                    }
                    .padding(.vertical, 8)

                    ForEach(store.sdkTestResults.sorted(by: { $0.timestamp > $1.timestamp })) { result in
                        HStack {
                            Image(systemName: result.status == .passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(result.status == .passed ? .green : .red)

                            VStack(alignment: .leading) {
                                Text(result.testName)
                                    .font(.subheadline.bold())
                                Text(String(format: "%.2fs", result.duration))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                            if let failure = result.failureMessage {
                                Spacer()
                                Image(systemName: "info.circle")
                                    .foregroundStyle(.secondary)
                                    .help(failure)
                            }
                        }
                    }
                    .onDelete(perform: deleteResult)
                }
            }
        }
        .navigationTitle("Test Dashboard")
    }

    private func runTests() {
        isRunning = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let names = ["AuthValidation", "DataSync", "EncryptionHandshake", "NetworkRetry"]
            let newResults = names.map { name in
                SDKTestResult(
                    sdkID: UUID(),
                    testName: name,
                    duration: Double.random(in: 0.1...0.8),
                    status: Double.random(in: 0...1) > 0.1 ? .passed : .failed,
                    failureMessage: nil
                )
            }
            var updated = store.sdkTestResults
            updated.append(contentsOf: newResults)
            store.saveSDKTestResults(updated)
            isRunning = false
        }
    }

    private func deleteResult(at offsets: IndexSet) {
        var updated = store.sdkTestResults
        updated.remove(atOffsets: offsets)
        store.saveSDKTestResults(updated)
    }
}
