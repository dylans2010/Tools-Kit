/*
 REDESIGN SUMMARY:
 - Standardized on insetGrouped List style.
 - Replaced manual card-based scenario configuration with native Section and Picker.
 - Modernized the execution button using a prominent prominent style and ProgressView.
 - Standardized execution status feedback using semantic Labels and status indicators.
 - strictly preserved all SDKExecutionKernel and SDKRuntimeEngine state management logic.
 - Standardized runtime parameter toggles using native SwiftUI components and semantic colors.
 - Improved visual hierarchy for scenario-specific success/failure reporting.
 */

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
            Section("Test Configuration") {
                Picker("Execution Scenario", selection: $selectedScenario) {
                    ForEach(0..<scenarios.count, id: \.self) { index in
                        Text(scenarios[index]).tag(index)
                    }
                }
                .pickerStyle(.menu)

                Button(action: runTest) {
                    HStack {
                        if testStatus == .running {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "play.fill")
                        }
                        Text(testStatus == .running ? "Executing Simulation..." : "Run Integration Lab")
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(testStatus == .running)
            }

            Section("Execution Output") {
                switch testStatus {
                case .idle:
                    Text("Awaiting execution trigger...").font(.caption).foregroundStyle(.secondary)
                case .running:
                    runningStatusLabel
                case .success(let msg):
                    Label(msg, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.subheadline)
                case .failure(let err):
                    Label(err, systemImage: "exclamationmark.octagon.fill")
                        .foregroundStyle(.red)
                        .font(.subheadline)
                }
            }

            Section("Environment Parameters") {
                Toggle("Enforce Scope Validation", isOn: $enableScopeValidation)

                Toggle(isOn: $runtime.isNoSandboxModeEnabled) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("No-Sandbox Mode")
                            Text("Bypass kernel restrictions")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "shield.slash")
                            .foregroundStyle(runtime.isNoSandboxModeEnabled ? .red : .secondary)
                    }
                }
                .tint(.red)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Integration Lab")
        .navigationBarTitleDisplayMode(.inline)
    }


    @ViewBuilder
    private var runningStatusLabel: some View {
        if #available(iOS 18.0, *) {
            Label("Running: \(scenarios[selectedScenario])", systemImage: "arrow.triangle.2.circlepath")
                .symbolEffect(.rotate, options: .repeating)
                .font(.subheadline.bold())
        } else {
            Label("Running: \(scenarios[selectedScenario])", systemImage: "arrow.triangle.2.circlepath")
                .font(.subheadline.bold())
        }
    }
    private func runTest() {
        testStatus = .running
        Task {
            let context = SDKExecutionContext(projectID: UUID(), noSandbox: runtime.isNoSandboxModeEnabled)
            do {
                switch selectedScenario {
                case 0:
                    try await SDKExecutionKernel.shared.execute(action: .createNote(title: "Test Note", content: "Lab simulation"), context: context)
                    testStatus = .success(message: "Mail flow validation successful via Kernel.")
                case 1:
                    try await SDKExecutionKernel.shared.execute(action: .createNote(title: "Refactor", content: "Cleanup"), context: context)
                    try await SDKExecutionKernel.shared.execute(action: .createTask(title: "Refactor Task", dueDate: Date()), context: context)
                    testStatus = .success(message: "Note-to-Task pipeline integrity verified.")
                default:
                    testStatus = .success(message: "Scenario \(scenarios[selectedScenario]) completed.")
                }
            } catch {
                testStatus = .failure(error: error.localizedDescription)
            }
        }
    }

    enum TestStatus: Equatable {
        case idle, running
        case success(message: String)
        case failure(error: String)
    }
}
