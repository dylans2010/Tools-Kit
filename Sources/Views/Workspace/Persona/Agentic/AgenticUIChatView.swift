import SwiftUI

struct AgenticUIChatView: View {
    @StateObject private var orchestrator = AgenticCoreOrchestrator.shared
    @StateObject private var traceStore = AgenticExecutionTraceStore.shared
    @State private var query = ""

    var body: some View {
        VStack(spacing: 0) {
            if orchestrator.deviceCapability?.isSupported == false {
                ContentUnavailableView(
                    "Agent Unavailable",
                    systemImage: "lock.shield",
                    description: Text(orchestrator.deviceCapability?.reason ?? "Device does not support Foundation Models.")
                )
            } else {
                ScrollView {
                    ScrollViewReader { proxy in
                        LazyVStack(spacing: 16) {
                            ForEach(traceStore.traces) { trace in
                                AgenticExecutionCard(trace: trace)
                            }

                            if !orchestrator.streamingTokens.isEmpty {
                                AgenticStreamingBubble(text: orchestrator.streamingTokens)
                                    .id("streaming_anchor")
                            }

                            if orchestrator.isProcessing && orchestrator.streamingTokens.isEmpty {
                                HStack {
                                    ProgressView()
                                        .padding(.trailing, 8)
                                    Text("Agent is preparing...")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                                .padding()
                                .id("loading_anchor")
                            }
                        }
                        .padding()
                        .onChange(of: orchestrator.streamingTokens) { _ in
                            proxy.scrollTo("streaming_anchor", anchor: .bottom)
                        }
                    }
                }
            }

            VStack {
                Divider()
                HStack {
                    TextField("Command the agent...", text: $query)
                        .textFieldStyle(.roundedBorder)
                        .disabled(orchestrator.isProcessing || orchestrator.deviceCapability?.isSupported == false)

                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                    }
                    .disabled(query.isEmpty || orchestrator.isProcessing || orchestrator.deviceCapability?.isSupported == false)
                }
                .padding()
            }
            .background(.ultraThinMaterial)
        }
        .navigationTitle("Agent Chat")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sendMessage() {
        let text = query
        query = ""
        Task {
            await orchestrator.processRequest(text)
        }
    }
}

struct AgenticStreamingBubble: View {
    let text: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(text)
                    .font(.subheadline)
                    .padding(12)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(18)

                Text("Reasoning live...")
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
            }
            Spacer()
        }
    }
}
