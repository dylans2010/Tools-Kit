import SwiftUI

struct DeveloperLogsView: View {
    @State private var searchText = ""
    @State private var severityFilter: LogLevel?
    @State private var isLive = true
    @ObservedObject var logStore = SDKLogStore.shared

    var filteredLogs: [SDKLogEntry] {
        logStore.entries.filter { log in
            (searchText.isEmpty || log.message.localizedCaseInsensitiveContains(searchText) || log.source.localizedCaseInsensitiveContains(searchText)) &&
            (severityFilter == nil || log.level == severityFilter)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            logFilterBar

            if filteredLogs.isEmpty {
                ContentUnavailableView("No Logs", systemImage: "list.bullet.rectangle", description: Text("No log entries match your filters."))
            } else {
                List {
                    ForEach(filteredLogs) { log in
                        DeveloperLogEntryRow(log: log)
                    }
                }
                .listStyle(.plain)
            }
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
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    logStore.clear()
                } label: {
                    Image(systemName: "trash")
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
                    ForEach(LogLevel.allCases, id: \.self) { level in
                        FilterChip(label: level.rawValue.uppercased(), isSelected: severityFilter == level) { severityFilter = level }
                    }
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
    }
}

struct DeveloperLogEntryRow: View {
    let log: SDKLogEntry
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(log.timestamp.formatted(.dateTime.hour().minute().second()))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)

                Text(log.level.rawValue.uppercased())
                    .font(.system(size: 8, weight: .bold))
                    .padding(.horizontal, 4).padding(.vertical, 2)
                    .background(colorFor(log.level).opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
                    .foregroundStyle(colorFor(log.level))

                Text(log.source).font(.system(size: 10, weight: .bold))

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }

            Text(log.message)
                .font(.system(size: 12, design: .monospaced))

            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Metadata")
                        .font(.caption.bold())
                    Text("No additional payload available.")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
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

    private func colorFor(_ level: LogLevel) -> Color {
        switch level {
        case .debug: return .gray
        case .info: return .blue
        case .warn: return .orange
        case .error: return .red
        case .critical: return .purple
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
