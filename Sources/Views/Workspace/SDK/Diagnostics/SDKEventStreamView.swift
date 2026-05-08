import SwiftUI
import Combine

struct SDKEventStreamView: View {
    @State private var events: [SDKEventLog] = []
    @State private var eventSubscription: AnyCancellable?
    @State private var filterText = ""

    var filteredEvents: [SDKEventLog] {
        guard !filterText.isEmpty else { return events }
        return events.filter { $0.type.localizedCaseInsensitiveContains(filterText) || $0.description.localizedCaseInsensitiveContains(filterText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Live System Events").font(.headline)
                Spacer()
                Circle().fill(.red).frame(width: 8, height: 8)
                Text("LIVE").font(.caption).bold()
                Text("(\(events.count))").font(.caption).foregroundStyle(.secondary)
            }
            .padding()
            .background(.thinMaterial)

            TextField("Filter Events", text: $filterText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .padding(.vertical, 6)

            List(filteredEvents) { event in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(event.timestamp, style: .time)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)

                        Text(event.type)
                            .font(.system(.caption, design: .monospaced))
                            .bold()
                            .padding(.horizontal, 4)
                            .background(colorForType(event.type).opacity(0.1))
                            .cornerRadius(4)

                        if let source = event.source {
                            Text(source)
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }

                    Text(event.description)
                        .font(.subheadline)
                }
                .padding(.vertical, 4)
            }
            .listStyle(.plain)

            HStack {
                Button("Clear") { events.removeAll() }
                Spacer()
                Button("Replay Last 50") { replayEvents() }
            }
            .padding()
            .background(.thinMaterial)
        }
        .navigationTitle("Event Stream")
        .onAppear {
            setupStream()
        }
        .onDisappear {
            eventSubscription?.cancel()
        }
    }

    private func setupStream() {
        PluginEventBus.shared.subscribe { event in
            DispatchQueue.main.async {
                let log = SDKEventLog(type: event.capability.rawValue.uppercased(), description: event.action)
                self.events.insert(log, at: 0)
            }
        }

        eventSubscription = SDKEventBridge.shared.subscribeAll { sdkEvent in
            let log = SDKEventLog(type: sdkEvent.type, description: sdkEvent.stringPayload.map { "\($0.key)=\($0.value)" }.joined(separator: ", "), source: sdkEvent.source)
            self.events.insert(log, at: 0)
        }
    }

    private func replayEvents() {
        let from = Date().addingTimeInterval(-3600)
        let replayed = SDKEventBridge.shared.replay(from: from, to: Date())
        for event in replayed.prefix(50) {
            let log = SDKEventLog(type: event.type, description: event.stringPayload.map { "\($0.key)=\($0.value)" }.joined(separator: ", "), source: event.source)
            events.insert(log, at: 0)
        }
    }

    private func colorForType(_ type: String) -> Color {
        if type.contains("ERROR") { return .red }
        if type.contains("WARN") { return .orange }
        if type.contains("realtime") { return .purple }
        return .blue
    }
}

struct SDKEventLog: Identifiable {
    let id = UUID()
    let type: String
    let description: String
    let timestamp = Date()
    var source: String? = nil
}
