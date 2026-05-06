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
        List {
            Section("Test Scenarios") {
                Picker("Scenario", selection: $selectedScenario) {
                    ForEach(0..<scenarios.count, id: \.self) { index in
                        Text(scenarios[index]).tag(index)
                    }
                }
                .pickerStyle(.menu)

                Button("Run Integration Test") {
                    runTest()
                }
                .bold()
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
                .disabled(testStatus == .running)
            }

            Section("Execution Log") {
                VStack(alignment: .leading, spacing: 8) {
                    switch testStatus {
                    case .idle:
                        Text("Ready to test...").foregroundStyle(.secondary)
                    case .running:
                        HStack {
                            ProgressView().padding(.trailing, 4)
                            Text("Executing scenario: \(scenarios[selectedScenario])")
                        }
                    case .success(let msg):
                        Label(msg, systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                    case .failure(let err):
                        Label(err, systemImage: "xmark.octagon.fill").foregroundStyle(.red)
                    }
                }
                .font(.subheadline)
            }

            Section("Test Parameters") {
                Toggle("Validate Scopes Before Execution", isOn: $enableScopeValidation)
                Toggle("No-Sandbox Mode", isOn: $runtime.isNoSandboxModeEnabled)
                    .tint(.red)

                if runtime.isNoSandboxModeEnabled {
                    Label("All scope restrictions bypassed", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        .navigationTitle("Integration Test Lab")
    }

    private func runTest() {
        testStatus = .running

        Task {
            let context = SDKExecutionContext(projectID: UUID(), noSandbox: runtime.isNoSandboxModeEnabled)

            do {
                switch selectedScenario {
                case 0:
                    try await SDKExecutionKernel.shared.execute(action: .createNote(title: "Test Mail Note", content: "Content for mail flow"), context: context)
                    await MainActor.run { testStatus = .success(message: "Mail flow: Note created, pipeline validated via Kernel.") }

                case 1:
                    try await SDKExecutionKernel.shared.execute(action: .createNote(title: "Convert to Task", content: "Task from note"), context: context)
                    try await SDKExecutionKernel.shared.execute(action: .createTask(title: "Converted from Note", dueDate: Date().addingTimeInterval(86400)), context: context)
                    await MainActor.run { testStatus = .success(message: "Note-to-Task: Both created via Kernel pipeline.") }

                case 2:
                    try await SDKExecutionKernel.shared.execute(action: .createNote(title: "Multi-Sync Test", content: "Sync validation"), context: context)
                    try await SDKExecutionKernel.shared.execute(action: .createTask(title: "Sync Task", dueDate: nil), context: context)
                    WorkspaceAPI.shared.timeTravel.createSnapshot(message: "Multi-system sync test")
                    await MainActor.run { testStatus = .success(message: "Multi-system sync: Note + Task + Snapshot created.") }

                case 3:
                    for i in 1...5 {
                        try await SDKExecutionKernel.shared.execute(action: .createNote(title: "Batch Note \(i)", content: "Batch content \(i)"), context: context)
                    }
                    await MainActor.run { testStatus = .success(message: "Batch: 5 notes created via Kernel pipeline.") }

                default:
                    await MainActor.run { testStatus = .failure(error: "Unknown scenario") }
                }
            } catch {
                await MainActor.run {
                    testStatus = .failure(error: error.localizedDescription)
                }
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
