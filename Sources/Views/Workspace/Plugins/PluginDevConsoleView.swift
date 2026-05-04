import SwiftUI

struct PluginDevConsoleView: View {
    @StateObject private var eventBus = PluginEventBus.shared
    @StateObject private var runtime = PluginRuntime.shared
    @StateObject private var manager = PluginManager.shared

    @State private var selectedTab: ConsoleTab = .events

    enum ConsoleTab: String, CaseIterable {
        case events = "Events"
        case logs = "Logs"
        case trigger = "Trigger"
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Tab", selection: $selectedTab) {
                ForEach(ConsoleTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            Divider()

            switch selectedTab {
            case .events:
                eventsList
            case .logs:
                logsList
            case .trigger:
                triggerPanel
            }
        }
        .navigationTitle("Plugin Dev Console")
    }

    private var eventsList: some View {
        List(eventBus.recentEvents) { event in
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.type.rawValue)
                        .font(.subheadline.bold())
                        .foregroundColor(.blue)
                    Spacer()
                    Text(event.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Text("Capability: \(event.capability.rawValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if !event.payload.isEmpty {
                    Text(event.payload.description)
                        .font(.system(.caption2, design: .monospaced))
                        .padding(4)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(4)
                }
            }
        }
    }

    private var logsList: some View {
        List(runtime.logs) { log in
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(manager.installedPlugins.first(where: { $0.id == log.pluginID })?.name ?? "Unknown Plugin")
                        .font(.subheadline.bold())
                    Spacer()
                    Text(log.status.rawValue.uppercased())
                        .font(.caption2.bold())
                        .foregroundColor(log.status == .success ? .green : .red)
                }
                Text(log.output)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                Text(log.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.tertiary)
            }
        }
    }

    private var triggerPanel: some View {
        Form {
            Section("Manual Event Trigger") {
                ForEach(PluginAction.allCases) { action in
                    Button {
                        eventBus.emit(type: action, payload: ["manual": "true", "triggeredAt": Date().description])
                    } label: {
                        HStack {
                            Text(action.rawValue)
                            Spacer()
                            Image(systemName: "play.circle.fill")
                        }
                    }
                }
            }

            Section {
                Text("Triggering an event here will cause all enabled plugins subscribed to that action to execute immediately in the sandbox.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
