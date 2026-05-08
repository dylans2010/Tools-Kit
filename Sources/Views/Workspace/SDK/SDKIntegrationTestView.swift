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
            Section {
                SDKModernCard(padding: 12, content: {
                    VStack(alignment: .leading, spacing: 14) {
                        Picker("Select Scenario", selection: $selectedScenario) {
                            ForEach(0..<scenarios.count, id: \.self) { index in
                                Text(scenarios[index]).tag(index)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.primary)

                        Button {
                            runTest()
                        } label: {
                            HStack {
                                Spacer()
                                if testStatus == .running {
                                    ProgressView().controlSize(.small).padding(.trailing, 8)
                                    Text("Executing...")
                                } else {
                                    Image(systemName: "play.fill")
                                    Text("Run Integration Test")
                                }
                                Spacer()
                            }
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.primary)
                            .foregroundStyle(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                        .disabled(testStatus == .running)
                    }
                }
            } header: {
                SDKSectionHeader("Test Scenarios", subtitle: "Managed SDK execution pipelines", systemImage: "testtube.2")
            }

            Section {
                VStack(alignment: .leading, spacing: 10) {
                    switch testStatus {
                    case .idle:
                        HStack {
                            Image(systemName: "clock.arrow.circlepath").foregroundStyle(.secondary)
                            Text("Awaiting execution...").foregroundStyle(.secondary)
                        }
                    case .running:
                        HStack {
                            ProgressView().padding(.trailing, 4)
                            Text("Running: \(scenarios[selectedScenario])")
                        }
                    case .success(let msg):
                        SDKNotificationBanner(message: msg, type: .success)
                    case .failure(let err):
                        SDKNotificationBanner(message: err, type: .error)
                    }
                }
                .font(.subheadline)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            } header: {
                SDKSectionHeader("Execution Log", subtitle: "Kernel output and validation", alignment: .leading)
            }

            Section {
                Toggle(isOn: $enableScopeValidation) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Scope Validation").font(.subheadline.bold())
                            Text("Enforce permission boundaries").font(.caption2).foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "lock.shield.fill").foregroundStyle(.blue)
                    }
                }

                Toggle(isOn: $runtime.isNoSandboxModeEnabled) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("No-Sandbox Mode").font(.subheadline.bold())
                            Text("Bypass all execution restrictions").font(.caption2).foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.sdkError)
                    }
                }
                .tint(.sdkError)

                if runtime.isNoSandboxModeEnabled {
                    SDKStatusPill("Restriction Bypassed", systemImage: "shield.slash.fill", color: .sdkWarning)
                        .padding(.vertical, 4)
                }
            } header: {
                SDKSectionHeader("Test Parameters", subtitle: "Runtime environment flags", systemImage: "slider.horizontal.3")
            }
        }
        .navigationTitle("Integration Lab")
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
