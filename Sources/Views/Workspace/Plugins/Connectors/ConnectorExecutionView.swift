import SwiftUI

struct ConnectorExecutionView: View {
    @State var connector: ConnectorDefinition
    @StateObject private var runtime = ConnectorRuntime.shared

    var isRunning: Bool {
        runtime.activeRunningConnectors.contains(connector.id)
    }

    var body: some View {
        VStack(spacing: 0) {
            executionHeader

            if isRunning {
                executionTimeline
            } else {
                idleState
            }

            Spacer()

            actionButton
        }
        .navigationTitle("Live Execution")
        .background(Color(.systemGroupedBackground))
    }

    private var executionHeader: some View {
        VStack(spacing: 8) {
            Image(systemName: isRunning ? "arrow.triangle.2.circlepath" : "play.circle")
                .font(.system(size: 48))
                .foregroundColor(isRunning ? .blue : .secondary)
                .symbolEffect(.bounce, options: .repeating, value: isRunning)

            Text(isRunning ? "Executing Pipeline..." : "Pipeline Idle")
                .font(.headline)

            Text(connector.name)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(.background)
    }

    private var executionTimeline: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Step-by-Step Progress")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                ForEach(connector.flow.steps) { step in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)

                        VStack(alignment: .leading) {
                            Text(step.type.rawValue.capitalized)
                                .font(.subheadline.bold())
                            if let name = step.config["name"] {
                                Text(name).font(.caption).foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    .padding()
                    .background(.background)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }

    private var idleState: some View {
        VStack(spacing: 12) {
            Image(systemName: "checklist")
                .font(.title)
                .foregroundColor(.secondary)
            Text("No active execution session.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 64)
    }

    private var actionButton: some View {
        VStack {
            Button {
                Task {
                    await runtime.run(connector: connector)
                }
            } label: {
                Text(isRunning ? "Running..." : "Start Execution")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isRunning ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .bold()
            }
            .disabled(isRunning)
            .padding()
        }
        .background(.background)
    }
}
