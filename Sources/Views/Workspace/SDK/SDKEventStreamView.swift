import SwiftUI

struct SDKEventStreamView: View {
    @State private var events: [SDKEventLog] = []

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Live System Events").font(.headline)
                Spacer()
                Circle().fill(.red).frame(width: 8, height: 8)
                Text("LIVE").font(.caption).bold()
            }
            .padding()
            .background(.thinMaterial)

            List(events) { event in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(event.timestamp, style: .time)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)

                        Text(event.type)
                            .font(.system(.caption, design: .monospaced))
                            .bold()
                            .padding(.horizontal, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)

                        Spacer()
                    }

                    Text(event.description)
                        .font(.subheadline)
                }
                .padding(.vertical, 4)
            }
            .listStyle(.plain)
        }
        .navigationTitle("Event Stream")
        .onAppear {
            setupStream()
        }
    }

    private func setupStream() {
        // Connect to real PluginEventBus
        PluginEventBus.shared.subscribe { event in
            DispatchQueue.main.async {
                let log = SDKEventLog(type: event.capability.rawValue.uppercased(), description: event.action)
                self.events.insert(log, at: 0)
            }
        }
    }
}

struct SDKEventLog: Identifiable {
    let id = UUID()
    let type: String
    let description: String
    let timestamp = Date()
}
