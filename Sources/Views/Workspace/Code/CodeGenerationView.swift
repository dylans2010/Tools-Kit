import SwiftUI

struct CodeGenerationView: View {
    @ObservedObject var analyzer: CodeAnalyzer
    @Environment(\.dismiss) var dismiss

    @State private var logs: [String] = []
    @State private var progress: Double = 0
    @State private var isComplete = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack {
                    ProgressView(value: progress)
                        .accentColor(.purple)

                    HStack {
                        Text("\(Int(progress * 100))%")
                        Spacer()
                        Text(isComplete ? "Done" : "Processing...")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
                }
                .padding()
                .background(Color(.secondarySystemBackground))

                // Logs
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(logs, id: \.self) { log in
                                Text(log)
                                    .font(.system(size: 12, design: .monospaced))
                                    .padding(.horizontal)
                                    .id(log)
                            }
                        }
                        .padding(.vertical)
                    }
                    .onChange(of: logs) { _ in
                        if let last = logs.last {
                            proxy.scrollTo(last, anchor: .bottom)
                        }
                    }
                }

                if isComplete {
                    Button("Close") { dismiss() }
                        .buttonStyle(.borderedProminent)
                        .padding()
                }
            }
            .navigationTitle("Code Generation")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                startGeneration()
            }
        }
    }

    private func startGeneration() {
        logs.append("Initializing Agent Mode...")
        logs.append("Targeting Sources/Workspace/Code/...")

        Task {
            let transformer = CodeTransformer()
            let actions = analyzer.importPlan.filter { $0.action != .discard }
            let total = Double(actions.count)
            let apiKey = APIKeyManager.shared.getKey(for: "jules") ?? ""

            for (index, action) in actions.enumerated() {
                await MainActor.run {
                    logs.append("[\(action.action.rawValue.uppercased())] \(action.module.name) -> \(action.targetPath)")
                }

                do {
                    let result = try await transformer.transform(action: action, apiKey: apiKey)
                    await MainActor.run {
                        logs.append("✨ \(result)")
                        progress = Double(index + 1) / total
                    }
                } catch {
                    await MainActor.run {
                        logs.append("❌ Error: \(error.localizedDescription)")
                    }
                }

                try? await Task.sleep(nanoseconds: 300_000_000)
            }

            await MainActor.run {
                logs.append("✅ Integration complete.")
                isComplete = true
            }
        }
    }
}
