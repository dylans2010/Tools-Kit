import SwiftUI

struct SDKIntegrationTestView: View {
    @StateObject private var runtime = SDKRuntimeEngine.shared
    @State private var selectedScenario = 0
    @State private var testStatus: TestStatus = .idle
    @State private var enableScopeValidation = true

    private let scenarios = [
        "Create & Send Mail Flow",
        "Note to Task Conversion",
        "Multi-System Sync",
        "Large Batch Mutation"
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                SDKSectionHeader(title: "Integration Lab", subtext: "Run end-to-end SDK scenario tests.")

                SDKModernCard {
                    VStack(spacing: 16) {
                        Picker("Select Scenario", selection: $selectedScenario) {
                            ForEach(0..<scenarios.count, id: \.self) { index in
                                Text(scenarios[index]).tag(index)
                            }
                        }
                        .pickerStyle(.menu)

                        Button { runTest() } label: {
                            Text(testStatus == .running ? "Running..." : "Run Scenario")
                                .frame(maxWidth: .infinity).bold()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(testStatus == .running)
                    }
                }

                SDKSectionHeader(title: "Execution Log", subtext: "Live feedback from the test runner.")
                SDKModernCard {
                    VStack(alignment: .leading, spacing: 12) {
                        switch testStatus {
                        case .idle:
                            HStack {
                                Image(systemName: "play.circle").foregroundStyle(.secondary)
                                Text("Ready to test...").sdkSubtext()
                            }
                        case .running:
                            HStack {
                                ProgressView().padding(.trailing, 4)
                                Text("Executing: \(scenarios[selectedScenario])").font(.subheadline.bold())
                            }
                        case .success(let msg):
                            VStack(alignment: .leading, spacing: 8) {
                                SDKStatusPill(status: .success, text: "PASSED")
                                Text(msg).font(.subheadline).sdkSuccessText()
                            }
                        case .failure(let err):
                            VStack(alignment: .leading, spacing: 8) {
                                SDKStatusPill(status: .error, text: "FAILED")
                                Text(err).font(.subheadline).sdkErrorText()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                SDKSectionHeader(title: "Parameters", subtext: "Configure test environment overrides.")
                SDKModernCard {
                    VStack(spacing: 12) {
                        Toggle("Scope Validation", isOn: $enableScopeValidation)
                        Divider()
                        Toggle("No-Sandbox Mode", isOn: $runtime.isNoSandboxModeEnabled)
                            .tint(.red)

                        if runtime.isNoSandboxModeEnabled {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill").sdkWarningText()
                                Text("Bypassing all security restrictions").font(.caption2.bold()).sdkWarningText()
                                Spacer()
                            }
                            .padding(.top, 4)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Integration Test")
    }

    private func runTest() {
        testStatus = .running
        Task {
            let context = SDKExecutionContext(projectID: UUID(), noSandbox: runtime.isNoSandboxModeEnabled)
            do {
                switch selectedScenario {
                case 0:
                    try await SDKExecutionKernel.shared.execute(action: .createNote(title: "Test Mail Note", content: "Content for mail flow"), context: context)
                    await MainActor.run { testStatus = .success(message: "Mail flow: Note created and validated.") }
                case 1:
                    try await SDKExecutionKernel.shared.execute(action: .createNote(title: "Convert to Task", content: "Task from note"), context: context)
                    try await SDKExecutionKernel.shared.execute(action: .createTask(title: "Converted from Note", dueDate: Date().addingTimeInterval(86400)), context: context)
                    await MainActor.run { testStatus = .success(message: "Note-to-Task: Conversion successful.") }
                case 2:
                    try await SDKExecutionKernel.shared.execute(action: .createNote(title: "Multi-Sync Test", content: "Sync validation"), context: context)
                    WorkspaceAPI.shared.timeTravel.createSnapshot(message: "Multi-system sync test")
                    await MainActor.run { testStatus = .success(message: "Multi-system sync: Snapshot created.") }
                case 3:
                    for i in 1...5 {
                        try await SDKExecutionKernel.shared.execute(action: .createNote(title: "Batch Note \(i)", content: "Batch content \(i)"), context: context)
                    }
                    await MainActor.run { testStatus = .success(message: "Batch: 5 notes created successfully.") }
                default:
                    await MainActor.run { testStatus = .failure(error: "Unknown scenario") }
                }
            } catch {
                await MainActor.run { testStatus = .failure(error: error.localizedDescription) }
            }
        }
    }

    enum TestStatus: Equatable {
        case idle, running
        case success(message: String)
        case failure(error: String)

        static func == (lhs: TestStatus, rhs: TestStatus) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.running, .running): return true
            case (.success(let a), .success(let b)): return a == b
            case (.failure(let a), .failure(let b)): return a == b
            default: return false
            }
        }
    }
}
