import SwiftUI

struct SDKTestRunnerView: View {
    @StateObject private var harness = SDKTestHarness.shared
    @State private var isRunning = false

    var body: some View {
        List {
            Section("Controls") {
                HStack {
                    Button {
                        Task { await runAll() }
                    } label: {
                        Label("Run All Tests", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isRunning)

                    if isRunning {
                        ProgressView()
                            .padding(.leading, 8)
                    }

                    Spacer()

                    Button("Register Defaults") {
                        harness.registerDefaultSuites()
                    }
                    .buttonStyle(.bordered)
                }
            }

            Section("Test Suites (\(harness.testSuites.count))") {
                if harness.testSuites.isEmpty {
                    ContentUnavailableView("No Test Suites", systemImage: "testtube.2", description: Text("Register test suites to get started."))
                } else {
                    ForEach(harness.testSuites) { suite in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(suite.name)
                                .font(.headline)
                            Text("\(suite.cases.count) test cases")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            ForEach(suite.cases) { tc in
                                HStack {
                                    Image(systemName: "circle")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text(tc.name)
                                        .font(.caption)
                                }
                                .padding(.leading, 8)
                            }
                        }
                    }
                }
            }

            if let result = harness.lastRunResult {
                Section("Last Run") {
                    HStack(spacing: 16) {
                        resultCard(title: "Passed", value: "\(result.passedCount)", color: .green)
                        resultCard(title: "Failed", value: "\(result.failedCount)", color: .red)
                        resultCard(title: "Total", value: "\(result.totalCount)", color: .blue)
                    }
                    LabeledContent("Duration", value: String(format: "%.2fs", result.duration))
                    LabeledContent("All Passed", value: result.allPassed ? "Yes" : "No")
                }

                Section("Results") {
                    ForEach(result.caseResults) { caseResult in
                        HStack {
                            Image(systemName: caseResult.status == .passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(caseResult.status == .passed ? .green : .red)
                            VStack(alignment: .leading) {
                                Text(caseResult.caseName)
                                    .font(.subheadline)
                                Text(caseResult.suiteName)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(String(format: "%.0fms", caseResult.duration * 1000))
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        if let error = caseResult.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .padding(.leading, 28)
                        }
                    }
                }
            }

            if !harness.runHistory.isEmpty {
                Section("History (\(harness.runHistory.count) runs)") {
                    ForEach(harness.runHistory) { run in
                        HStack {
                            Image(systemName: run.allPassed ? "checkmark.circle" : "xmark.circle")
                                .foregroundStyle(run.allPassed ? .green : .red)
                            Text("\(run.passedCount)/\(run.totalCount) passed")
                                .font(.caption)
                            Spacer()
                            Text(run.startedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Test Runner")
    }

    private func resultCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.title2.bold()).foregroundStyle(color)
            Text(title).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func runAll() async {
        isRunning = true
        _ = await harness.runAll()
        isRunning = false
    }
}
