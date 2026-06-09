import SwiftUI

struct MCPConnectStateChip: View {
    let invocation: MCPToolInvocation
    @State private var showingDetail = false

    var body: some View {
        Button {
            showingDetail = true
        } label: {
            HStack(spacing: 8) {
                ZStack {
                    if invocation.status == .connecting || invocation.status == .executing {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: invocation.status.systemImage)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(invocation.status.color)
                    }
                }
                .frame(width: 20, height: 20)

                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 4) {
                        Text(invocation.serverName)
                            .font(.system(size: 11, weight: .bold))
                        Text("→")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                        Text(invocation.toolName)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    }

                    Text(invocation.purpose)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary.opacity(0.5))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(invocation.status.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(invocation.status.color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDetail) {
            MCPConnectStateDetail(invocation: invocation)
        }
        .opacity(invocation.status == .connecting || invocation.status == .executing ? 1.0 : 0.9)
    }
}

struct MCPConnectStateDetail: View {
    let invocation: MCPToolInvocation
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(invocation.serverName)
                                .font(.title3.bold())
                            Text(invocation.toolName)
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        MCPStatusBadge(status: invocation.status)
                    }
                    .padding(.bottom, 10)

                    // Info Grid
                    VStack(spacing: 12) {
                        InfoRow(label: "Purpose", value: invocation.purpose)
                        InfoRow(label: "Started", value: invocation.startedAt.formatted(date: .omitted, time: .standard))

                        if let completedAt = invocation.completedAt {
                            let duration = completedAt.timeIntervalSince(invocation.startedAt)
                            InfoRow(label: "Duration", value: String(format: "%.2fs", duration))
                        }
                    }

                    // Arguments
                    DisclosureGroup("Arguments") {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(invocation.arguments.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                HStack(alignment: .top) {
                                    Text(key)
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .frame(width: 100, alignment: .leading)
                                    Text("\(String(describing: value))")
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                    }
                    .font(.system(size: 14, weight: .semibold))

                    // Result / Error
                    VStack(alignment: .leading, spacing: 8) {
                        Text(invocation.errorMessage != nil ? "Error" : "Result")
                            .font(.system(size: 14, weight: .bold))

                        ScrollView {
                            Text(invocation.errorMessage ?? invocation.result ?? "No output yet...")
                                .font(.system(size: 13, design: .monospaced))
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(invocation.errorMessage != nil ? Color.red.opacity(0.1) : Color.primary.opacity(0.05))
                                .cornerRadius(8)
                        }
                        .frame(maxHeight: 200)
                    }
                }
                .padding()
            }
            .navigationTitle("Tool Invocation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Dismiss") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct MCPConnectStateList: View {
    let invocations: [MCPToolInvocation]

    var body: some View {
        if !invocations.isEmpty {
            VStack(spacing: 8) {
                ForEach(invocations.prefix(5)) { invocation in
                    MCPConnectStateChip(invocation: invocation)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }
}

// MARK: - Local Helpers

private struct MCPStatusBadge: View {
    let status: MCPInvocationStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.systemImage)
            Text(status.label)
        }
        .font(.caption.bold())
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.1), in: Capsule())
        .foregroundStyle(status.color)
    }
}

private struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
        }
    }
}
