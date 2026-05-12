import SwiftUI
import Combine

struct SDKEventStreamView: View {
    @State private var events: [SDKBusEvent] = []
    @State private var selectedCategory: SDKEventCategory = .all
    @State private var isListening = true
    @State private var eventSubscription: AnyCancellable?

    enum SDKEventCategory: String, CaseIterable, Identifiable, Sendable {
        case all = "All", system = "System", data = "Data", security = "Security", network = "Network", other = "Other"
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .all: return "tray.2.fill"
            case .system: return "gearshape.fill"
            case .data: return "database.fill"
            case .security: return "shield.fill"
            case .network: return "network"
            case .other: return "questionmark.circle"
            }
        }
    }

    private func category(for event: SDKBusEvent) -> SDKEventCategory {
        switch event.channel.lowercased() {
        case "system": return .system
        case "data": return .data
        case "security": return .security
        case "network": return .network
        default: return .other
        }
    }

    var filteredEvents: [SDKBusEvent] {
        if selectedCategory == .all { return events }
        return events.filter { category(for: $0) == selectedCategory }
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 0) {
                    DetailMetricPill(label: "Buffer", value: "\(events.count)", color: .blue)
                    DetailMetricPill(label: "Active", value: isListening ? "YES" : "NO", color: isListening ? .green : .secondary)
                    DetailMetricPill(label: "Latest", value: events.first.map { category(for: $0).rawValue } ?? "-", color: .purple)
                }
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear).listRowInsets(EdgeInsets())

            Section {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(SDKEventCategory.allCases) { cat in Label(cat.rawValue, systemImage: cat.icon).tag(cat) }
                }.pickerStyle(.menu)
            }

            Section("Event Log") {
                if filteredEvents.isEmpty {
                    ContentUnavailableView("No Events", systemImage: "antenna.radiowaves.left.and.right", description: Text("Real-time kernel events will appear here."))
                } else {
                    ForEach(filteredEvents) { event in
                        EventStreamRow(event: event, category: category(for: event))
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Event Stream")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { isListening.toggle(); if isListening { setupSubscription() } else { eventSubscription?.cancel() } } label: {
                    Image(systemName: isListening ? "pause.circle.fill" : "play.circle.fill").foregroundStyle(isListening ? Color.orange : Color.green)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) { events.removeAll() } label: { Image(systemName: "trash") }
            }
        }
        .onAppear(perform: setupSubscription)
        .onDisappear { eventSubscription?.cancel() }
    }

    private func setupSubscription() {
        eventSubscription?.cancel()
        eventSubscription = SDKEventBus.shared.subscribeAll { event in
            events.insert(event, at: 0)
            if events.count > 100 { events.removeLast() }
        }
    }
}

private struct EventStreamRow: View {
    let event: SDKBusEvent
    let category: SDKEventStreamView.SDKEventCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(category.rawValue.uppercased())
                    .font(.system(size: 8, weight: .black))
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(categoryColor.opacity(0.1), in: Capsule())
                    .foregroundStyle(categoryColor)
                Spacer()
                Text(event.timestamp.formatted(date: .omitted, time: .standard))
                    .font(.caption2.monospaced()).foregroundStyle(.secondary)
            }
            Text(event.name).font(.subheadline.bold())
            Text(event.id.uuidString).font(.system(size: 7, design: .monospaced)).foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    private var categoryColor: Color {
        switch category {
        case .system: return .blue
        case .data: return .green
        case .security: return .red
        case .network: return .purple
        case .all, .other: return .gray
        }
    }
}

private struct DetailMetricPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.headline).foregroundStyle(color)
            Text(label).font(.caption2.bold()).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
