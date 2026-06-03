import SwiftUI

struct AutomatedTestRunnerView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared
    @State private var isRunning = false

    var body: some View {
        List {
            Section("Test Suites") {
                if store.testSuites.isEmpty {
                    Text("No test suites configured.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(store.testSuites) { suite in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(suite.name).font(.subheadline.bold())
                                Text("\(suite.testCount) tests").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            statusBadge(suite.lastResult)
                        }
                    }
                }
            }

            Section {
                Button {
                    isRunning = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        isRunning = false
                        var current = store.testSuites
                        for i in 0..<current.count {
                            current[i].lastResult = "Passed"
                        }
                        store.saveTestSuites(current)
                    }
                } label: {
                    if isRunning {
                        ProgressView("Executing...").frame(maxWidth: .infinity)
                    } else {
                        Label("Run Full Regression Suite", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle("Test Runner")
        .onAppear {
            if store.testSuites.isEmpty {
                store.saveTestSuites([
                    TestSuite(name: "Unit Tests", testCount: 1240, lastResult: "Passed"),
                    TestSuite(name: "Integration Tests", testCount: 450, lastResult: "Failed"),
                    TestSuite(name: "E2E UI Tests", testCount: 82, lastResult: "Pending")
                ])
            }
        }
    }

    private func statusBadge(_ result: String) -> some View {
        Text(result.uppercased())
            .font(.system(size: 8, weight: .bold))
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(badgeColor(result).opacity(0.1))
            .foregroundStyle(badgeColor(result))
            .clipShape(Capsule())
    }

    private func badgeColor(_ result: String) -> Color {
        switch result {
        case "Passed": return .green
        case "Failed": return .red
        case "Pending": return .orange
        default: return .secondary
        }
    }
}
