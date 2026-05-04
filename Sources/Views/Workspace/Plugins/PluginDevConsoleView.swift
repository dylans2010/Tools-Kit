import SwiftUI
import Combine

struct PluginDevConsoleView: View {
    @State private var logs: [String] = [
        "[System] Runtime initialized.",
        "[Sandbox] Ready for execution."
    ]
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(logs, id: \.self) { log in
                        Text(log)
                            .font(.system(.caption, design: .monospaced))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color.black)
            .foregroundColor(.green)

            Divider()

            HStack {
                Button("Inject Test Event") {
                    injectTestEvent()
                }
                .padding()
                Spacer()
                Button("Clear") {
                    logs.removeAll()
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
        }
        .navigationTitle("Debug Console")
        .onAppear(perform: setupEventLogging)
    }

    private func setupEventLogging() {
        PluginEventBus.shared.subscribe { event in
            let log = "[\(Date().formatted(date: .omitted, time: .standard))] EVENT: \(event.capability.rawValue).\(event.action)"
            logs.append(log)
            if logs.count > 100 { logs.removeFirst() }
        }
        .store(in: &cancellables)
    }

    private func injectTestEvent() {
        let event = PluginEvent(
            id: UUID(),
            capability: .notes,
            action: "created",
            payload: ["id": UUID().uuidString, "title": "Debug Note"],
            timestamp: Date()
        )
        PluginEventBus.shared.emit(event)
    }
}
