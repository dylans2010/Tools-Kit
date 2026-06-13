import SwiftUI

struct BridgeChatView: View {
    @StateObject private var bridgeService = BridgeService.shared
    @StateObject private var connectionManager = BridgeConnectionManager.shared
    @State private var inputText: String = ""
    @State private var isGenerating = false

    var body: some View {
        VStack(spacing: 0) {
            // Connection Header
            connectionHeader

            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(bridgeService.messages) { message in
                            BridgeMessageBubble(message: message)
                        }

                        if !bridgeService.pendingCommands.isEmpty {
                            Divider().padding(.vertical)
                            Text("Pending Executions")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)

                            ForEach(bridgeService.pendingCommands) { command in
                                CommandApprovalCard(command: command)
                            }
                        }
                    }
                    .padding()
                }
                .onChange(of: bridgeService.messages.count) { _, _ in
                    if let lastId = bridgeService.messages.last?.id {
                        withAnimation { proxy.scrollTo(lastId, anchor: .bottom) }
                    }
                }
            }

            // Input Area
            inputArea
        }
        .navigationTitle("Remote Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    bridgeService.clearChat()
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
    }

    private var connectionHeader: some View {
        HStack {
            Circle()
                .fill(connectionManager.connectionState.color)
                .frame(width: 8, height: 8)

            Text(connectionManager.activeDevice?.name ?? "Remote Host")
                .font(.caption)

            Spacer()

            Text("\(connectionManager.currentLatency)ms")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .overlay(Divider(), alignment: .bottom)
    }

    private var inputArea: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(alignment: .bottom, spacing: 12) {
                TextField("Message remote agent...", text: $inputText, axis: .vertical)
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(20)
                    .lineLimit(1...5)

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: isGenerating ? "stop.circle.fill" : "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .padding(.bottom, 6)
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }

    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        let text = inputText
        inputText = ""

        isGenerating = true
        Task {
            for await _ in bridgeService.sendMessage(text) {
                // Tokens stream in via BridgeService.messages
            }
            await MainActor.run { isGenerating = false }
        }
    }
}

struct BridgeMessageBubble: View {
    let message: BridgeMessage

    var body: some View {
        HStack {
            if message.sender == .user { Spacer() }

            VStack(alignment: message.sender == .user ? .trailing : .leading, spacing: 4) {
                if let source = message.agentSource {
                    Text(source.rawValue)
                        .font(.caption2.bold())
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }

                Text(message.content)
                    .padding(12)
                    .background(message.sender == .user ? Color.blue : Color(.secondarySystemBackground))
                    .foregroundColor(message.sender == .user ? .white : .primary)
                    .cornerRadius(16, corners: message.sender == .user ? [.topLeft, .topRight, .bottomLeft] : [.topLeft, .topRight, .bottomRight])

                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if message.sender == .host { Spacer() }
        }
    }
}

struct CommandApprovalCard: View {
    let command: BridgeCommand
    @StateObject private var service = BridgeService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "terminal.fill")
                    .foregroundColor(.orange)
                Text("Execution Request")
                    .font(.headline)
            }

            Text(command.fullCommand)
                .font(.system(.subheadline, design: .monospaced))
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.05))
                .cornerRadius(8)

            if let wd = command.workingDirectory {
                Text("Directory: \(wd)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 12) {
                Button(role: .destructive) {
                    service.rejectCommand(command)
                } label: {
                    Text("Reject")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    service.approveCommand(command)
                } label: {
                    Text("Approve")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange.opacity(0.3), lineWidth: 1))
    }
}

