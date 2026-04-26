import SwiftUI

struct AgentExecutionTimelineView: View {
    @ObservedObject var state: AgentSessionState

    var body: some View {
        ScrollView {
            if state.timeline.isEmpty {
                ContentUnavailableView(
                    "No Timeline Data",
                    systemImage: "clock",
                    description: Text("Timeline events will appear here as the agent progresses through its execution phases.")
                )
                .padding(.top, 40)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(state.timeline.sorted(by: { $0.timestamp < $1.timestamp })) { step in
                        TimelineStepRow(step: step,
                                        tools: state.timelineTools[step.id] ?? [],
                                        isLast: step.id == state.timeline.last?.id)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Execution Timeline")
    }
}

struct TimelineStepRow: View {
    let step: AgentTimelineStep
    let tools: [AgentToolExecution]
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                indicator
                if !isLast {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2)
                        .frame(minHeight: 40)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(step.step)
                        .font(.headline)
                    Spacer()
                    Text(step.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                statusBadge

                if !tools.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tools Used:")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)

                        ForEach(tools) { tool in
                            HStack {
                                Image(systemName: "hammer.fill")
                                    .font(.system(size: 8))
                                Text(tool.tool)
                                    .font(.system(.caption2, design: .monospaced))
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 4)
                }

                Divider()
                    .padding(.vertical, 8)
            }
        }
    }

    @ViewBuilder
    private var indicator: some View {
        let color: Color = {
            switch step.status {
            case "completed": return .green
            case "in_progress": return .blue
            case "failed": return .red
            default: return .gray
            }
        }()

        ZStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            if step.status == "in_progress" {
                Circle()
                    .stroke(color, lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .scaleEffect(1.2)
                    .opacity(0.5)
            }
        }
        .frame(width: 24, height: 24)
    }

    @ViewBuilder
    private var statusBadge: some View {
        Text(step.status.replacingOccurrences(of: "_", with: " ").capitalized)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(badgeColor.opacity(0.1))
            .foregroundColor(badgeColor)
            .cornerRadius(4)
    }

    private var badgeColor: Color {
        switch step.status {
        case "completed": return .green
        case "in_progress": return .blue
        case "failed": return .red
        default: return .secondary
        }
    }
}
