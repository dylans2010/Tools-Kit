import SwiftUI

struct SDKFramework: Identifiable, Codable {
    let id: UUID
    let name: String
    let entryPoint: String
    let hooks: [String]
    let dependencies: [String] // Package IDs
    let permissions: [String] // Required Scopes
    var status: FrameworkStatus = .idle
}

enum FrameworkStatus: String, Codable {
    case idle, validating, resolving, executing, error
}

@MainActor
class FrameworkManager: ObservableObject {
    static let shared = FrameworkManager()

    @Published var frameworks: [SDKFramework] = []
    @Published var activeTraces: [String] = []

    private init() {
        frameworks = [
            SDKFramework(id: UUID(), name: "Data Transformation Pipeline", entryPoint: "main.js", hooks: ["onStart", "onProcess"], dependencies: ["lodash", "moment"], permissions: ["workspace.read", "workspace.write", "framework.execute"]),
            SDKFramework(id: UUID(), name: "UI Extension Layer", entryPoint: "index.tsx", hooks: ["render", "update"], dependencies: ["react-lite"], permissions: ["workspace.read", "framework.execute"])
        ]
    }

    func executeFramework(_ framework: SDKFramework) async {
        guard let index = frameworks.firstIndex(where: { $0.id == framework.id }) else { return }

        do {
            updateStatus(at: index, to: .validating)
            addTrace("Validating framework \(framework.name)...")
            try await Task.sleep(nanoseconds: 300_000_000)

            // Scope validation
            for perm in framework.permissions {
                if !AuthorizationManager.shared.validateScope(perm, resourceType: "framework", resourceId: framework.name) {
                    throw FrameworkError.permissionDenied(perm)
                }
            }

            updateStatus(at: index, to: .resolving)
            addTrace("Resolving dependencies for \(framework.name): \(framework.dependencies.joined(separator: ", "))")
            try await Task.sleep(nanoseconds: 300_000_000)

            updateStatus(at: index, to: .executing)
            addTrace("Executing entry point: \(framework.entryPoint)")

            // Simulation of sandboxed execution
            try await Task.sleep(nanoseconds: 1_000_000_000)

            addTrace("Execution complete for \(framework.name). Result validated.")
            updateStatus(at: index, to: .idle)

        } catch {
            addTrace("Error executing \(framework.name): \(error.localizedDescription)")
            updateStatus(at: index, to: .error)
        }
    }

    private func updateStatus(at index: Int, to status: FrameworkStatus) {
        frameworks[index].status = status
    }

    private func addTrace(_ msg: String) {
        activeTraces.append("[\(Date())] \(msg)")
    }
}

enum FrameworkError: Error, LocalizedError {
    case permissionDenied(String)
    case executionFailed(String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied(let s): return "Permission denied: \(s)"
        case .executionFailed(let s): return "Execution failed: \(s)"
        }
    }
}

struct FrameworkManageView: View {
    @StateObject private var manager = FrameworkManager.shared

    var body: some View {
        List {
            Section("Execution Pipelines") {
                ForEach(manager.frameworks) { framework in
                    FrameworkRow(framework: framework)
                }
            }

            Section("Runtime Tracing & Monitoring") {
                if manager.activeTraces.isEmpty {
                    Text("No active traces").foregroundStyle(.secondary)
                } else {
                    ForEach(manager.activeTraces.reversed(), id: \.self) { trace in
                        Text(trace).font(.caption2.monospaced())
                    }
                }
            }
        }
        .navigationTitle("Frameworks")
    }
}

struct FrameworkRow: View {
    let framework: SDKFramework
    @StateObject private var manager = FrameworkManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(framework.name).font(.headline)
                    Text("Hooks: \(framework.hooks.joined(separator: ", "))").font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
                statusLabel(framework.status)
            }

            HStack {
                Text("Deps: \(framework.dependencies.joined(separator: ", "))")
                    .font(.system(size: 8).monospaced())
                    .padding(4)
                    .background(.quaternary)
                    .cornerRadius(4)

                Spacer()

                Button("Run") {
                    Task { await manager.executeFramework(framework) }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(framework.status != .idle && framework.status != .error)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func statusLabel(_ status: FrameworkStatus) -> some View {
        switch status {
        case .idle: EmptyView()
        case .validating: Label("Validating", systemImage: "shield.checkerboard").foregroundStyle(.blue).font(.caption2)
        case .resolving: Label("Resolving", systemImage: "arrow.3.trianglepath").foregroundStyle(.purple).font(.caption2)
        case .executing: Label("Executing", systemImage: "play.fill").foregroundStyle(.green).font(.caption2)
        case .error: Label("Error", systemImage: "exclamationmark.octagon.fill").foregroundStyle(.red).font(.caption2)
        }
    }
}
