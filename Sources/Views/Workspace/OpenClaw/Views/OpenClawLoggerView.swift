import SwiftUI
import UniformTypeIdentifiers

struct OpenClawLoggerView: View {
    @State private var logger = OpenClawLoggerService.shared
    @State private var searchText = ""
    @State private var selectedLevels: Set<OpenClawLogLevel> = Set(OpenClawLogLevel.allCases)
    @State private var selectedCategories: Set<OpenClawLogCategory> = Set(OpenClawLogCategory.allCases)
    @State private var isPaused = false
    @State private var autoScroll = true

    var filteredLogs: [OpenClawLogEntry] {
        logger.logs.filter { entry in
            let matchesSearch = searchText.isEmpty ||
                entry.title.localizedCaseInsensitiveContains(searchText) ||
                entry.description.localizedCaseInsensitiveContains(searchText) ||
                (entry.payload?.localizedCaseInsensitiveContains(searchText) ?? false)

            let matchesLevel = selectedLevels.contains(entry.level)
            let matchesCategory = selectedCategories.contains(entry.category)

            return matchesSearch && matchesLevel && matchesCategory
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            diagnosticsSummary

            filterBar

            ScrollViewReader { proxy in
                List {
                    ForEach(filteredLogs) { entry in
                        OpenClawLogEntryRow(entry: entry)
                            .id(entry.id)
                    }
                }
                .listStyle(.plain)
                .onChange(of: logger.logs.count) {
                    if autoScroll && !isPaused {
                        if let last = filteredLogs.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("OpenClaw Diagnostics")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search logs...")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    isPaused.toggle()
                } label: {
                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
                }

                Menu {
                    Button(role: .destructive) {
                        logger.clear()
                    } label: {
                        Label("Clear Logs", systemImage: "trash")
                    }

                    Button {
                        copyAllLogs()
                    } label: {
                        Label("Copy All Logs", systemImage: "doc.on.doc")
                    }

                    Section("Export") {
                        ShareLink(item: logger.exportAsText()) {
                            Label("Export as Plain Text", systemImage: "doc.text")
                        }

                        if let jsonData = logger.exportAsJSON(), let jsonString = String(data: jsonData, encoding: .utf8) {
                            ShareLink(item: jsonString) {
                                Label("Export as JSON", systemImage: "braces")
                            }
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }

    private var diagnosticsSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    SummaryItem(title: "Connection", value: "\(OpenClawService.shared.connectionState)")
                    SummaryItem(title: "Socket", value: logger.websocketState)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    SummaryItem(title: "Address", value: logger.gatewayAddress)
                    SummaryItem(title: "Service", value: logger.connectedServiceName)
                }
            }

            HStack {
                SummaryItem(title: "Auth", value: logger.deriveAuthState(from: OpenClawService.shared.connectionState))
                Spacer()
                SummaryItem(title: "Pairing", value: logger.derivePairingState(from: OpenClawService.shared.connectionState))
                Spacer()
                SummaryItem(title: "Session", value: logger.deriveSessionState(from: OpenClawService.shared.connectionState))
            }

            HStack {
                SummaryItem(title: "Logs", value: "\(logger.logs.count)")
                Spacer()
                SummaryItem(title: "Errors", value: "\(logger.errorCount)", color: .red)
                Spacer()
                SummaryItem(title: "Warnings", value: "\(logger.warningCount)", color: .orange)
                Spacer()
                SummaryItem(title: "Version", value: logger.protocolVersion)
            }

            HStack {
                if let startTime = logger.activeConnectionStartTime {
                    SummaryItem(title: "Active For", value: durationString(from: startTime))
                } else {
                    SummaryItem(title: "Active For", value: "--:--")
                }
                Spacer()
                if let lastHandshake = logger.lastHandshakeTime {
                    SummaryItem(title: "Last Handshake", value: formattedTime(lastHandshake))
                }
                Spacer()
                if let lastError = logger.lastErrorTime {
                    SummaryItem(title: "Last Error", value: formattedTime(lastError), color: .red)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Menu {
                    ForEach(OpenClawLogLevel.allCases, id: \.self) { level in
                        Toggle(level.rawValue, isOn: Binding(
                            get: { selectedLevels.contains(level) },
                            set: { if $0 { selectedLevels.insert(level) } else { selectedLevels.remove(level) } }
                        ))
                    }
                } label: {
                    HStack {
                        Text("Levels")
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
                }

                Menu {
                    ForEach(OpenClawLogCategory.allCases, id: \.self) { category in
                        Toggle(category.rawValue, isOn: Binding(
                            get: { selectedCategories.contains(category) },
                            set: { if $0 { selectedCategories.insert(category) } else { selectedCategories.remove(category) } }
                        ))
                    }
                } label: {
                    HStack {
                        Text("Categories")
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
                }

                Toggle(isOn: $autoScroll) {
                    Text("Auto-scroll")
                        .font(.caption)
                }
                .toggleStyle(.button)
                .tint(.blue)
                .controlSize(.mini)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(UIColor.systemBackground))
        .overlay(Divider(), alignment: .bottom)
    }

    private func copyAllLogs() {
        UIPasteboard.general.string = logger.exportAsText()
    }

    private func durationString(from date: Date) -> String {
        let duration = Date().timeIntervalSince(date)
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

struct OpenClawLogEntryRow: View {
    let entry: OpenClawLogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.formattedTimestamp)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)

                Text(entry.level.rawValue)
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(levelColor.opacity(0.2))
                    .foregroundStyle(levelColor)
                    .clipShape(RoundedRectangle(cornerRadius: 3))

                Text(entry.category.rawValue)
                    .font(.system(size: 9))
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 3))

                Spacer()
            }

            Text(entry.title)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))

            if !entry.description.isEmpty {
                Text(entry.description)
                    .font(.caption)
                    .foregroundStyle(.primary.opacity(0.8))
                    .lineLimit(3)
            }

            HStack {
                Text("C=\(entry.connectionState) A=\(entry.authState) P=\(entry.pairingState)")
                    .font(.system(size: 7, design: .monospaced))
                    .foregroundStyle(.secondary)

                Spacer()

                if entry.payload != nil {
                    Label("JSON", systemImage: "braces")
                        .font(.system(size: 8))
                        .foregroundStyle(.blue)
                }

                if entry.errorDetails != nil {
                    Label("ERROR", systemImage: "exclamationmark.circle")
                        .font(.system(size: 8))
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button {
                UIPasteboard.general.string = formatEntryFull(entry)
            } label: {
                Label("Copy Log", systemImage: "doc.on.doc")
            }

            if let payload = entry.payload {
                Button {
                    UIPasteboard.general.string = payload
                } label: {
                    Label("Copy JSON Payload", systemImage: "braces")
                }
            }

            if let error = entry.errorDetails {
                Button {
                    UIPasteboard.general.string = error
                } label: {
                    Label("Copy Error Details", systemImage: "exclamationmark.triangle")
                }
            }

            ShareLink("Share Log", item: formatEntryFull(entry))
        }
    }

    private var levelColor: Color {
        switch entry.level {
        case .debug: return .gray
        case .info: return .green
        case .warning: return .orange
        case .error: return .red
        }
    }

    private func formatEntryFull(_ entry: OpenClawLogEntry) -> String {
        var text = "[\(entry.formattedTimestamp)] [\(entry.level.rawValue)] [\(entry.category.rawValue)] \(entry.title)"
        if !entry.description.isEmpty {
            text += "\n\(entry.description)"
        }
        text += "\nStates: Conn=\(entry.connectionState), Auth=\(entry.authState), Pair=\(entry.pairingState), Session=\(entry.sessionState)"
        if let payload = entry.payload {
            text += "\nPayload: \(payload)"
        }
        if let error = entry.errorDetails {
            text += "\nError: \(error)"
        }
        return text
    }
}

struct SummaryItem: View {
    let title: String
    let value: String
    var color: Color = .primary

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text(value)
                .font(.system(.subheadline, design: .monospaced).weight(.bold))
                .foregroundStyle(color)
                .lineLimit(1)
        }
    }
}
