import SwiftUI

struct DeveloperLogsView: View {
    @State private var searchText = ""
    @State private var severityFilter: LogSeverity?
    @State private var isLive = true

    @State private var logs: [DeveloperLogEntry] = (0..<50).map { i in
        DeveloperLogEntry(
            id: UUID(),
            timestamp: Date().addingTimeInterval(Double(-i * 60)),
            severity: [.debug, .info, .warn, .error, .critical].randomElement()!,
            source: ["Auth", "Marketplace", "SDK", "API"].randomElement()!,
            eventType: ["Request", "Response", "Exception", "Validation"].randomElement()!,
            message: "Developer activity log entry sample #\(i + 1)",
            payload: "{\"request_id\": \"\(UUID().uuidString)\", \"latency\": \"45ms\"}"
        )
    }

    var filteredLogs: [DeveloperLogEntry] {
        logs.filter { log in
            (searchText.isEmpty || log.message.localizedCaseInsensitiveContains(searchText) || log.source.localizedCaseInsensitiveContains(searchText)) &&
            (severityFilter == nil || log.severity == severityFilter)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            logFilterBar

            List {
                ForEach(filteredLogs) { log in
                    LogEntryRow(log: log)
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("Developer Logs")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    if isLive {
                        Text("LIVE").font(.system(size: 8, weight: .bold)).foregroundStyle(.red)
                            .padding(.horizontal, 4).padding(.vertical, 2)
                            .background(.red.opacity(0.1), in: Capsule())
                    }
                    Button {
                        isLive.toggle()
                    } label: {
                        Image(systemName: isLive ? "pause.fill" : "play.fill")
                    }
                }
            }
        }
    }

    private var logFilterBar: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Filter logs...", text: $searchText)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }
                }
            }
            .padding(8)
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    FilterChip(label: "ALL", isSelected: severityFilter == nil) { severityFilter = nil }
                    ForEach(LogSeverity.allCases, id: \.self) { severity in
                        FilterChip(label: severity.rawValue, isSelected: severityFilter == severity) { severityFilter = severity }
                    }
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
    }
}

struct LogEntryRow: View {
    let log: DeveloperLogEntry
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(log.timestamp.formatted(.dateTime.hour().minute().second()))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)

                Text(log.severity.rawValue)
                    .font(.system(size: 8, weight: .bold))
                    .padding(.horizontal, 4).padding(.vertical, 2)
                    .background(log.severity.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
                    .foregroundStyle(log.severity.color)

                Text(log.source).font(.system(size: 10, weight: .bold))
                Text(log.eventType).font(.system(size: 10)).foregroundStyle(.secondary)

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }

            Text(log.message)
                .font(.system(size: 12, design: .monospaced))

            if isExpanded, let payload = log.payload {
                Text(payload)
                    .font(.system(size: 10, design: .monospaced))
                    .padding(8)
                    .background(Color.black.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.snappy) {
                isExpanded.toggle()
            }
        }
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.1))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
