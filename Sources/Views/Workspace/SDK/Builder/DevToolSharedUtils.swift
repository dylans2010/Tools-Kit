import SwiftUI

// MARK: - Shared UI Components

struct DevToolHeader: View {
    let title: String
    let description: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.accent)
                Text(title)
                    .font(.title2.bold())
            }
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct HistoryItem: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let title: String
    let detail: String

    init(title: String, detail: String) {
        self.id = UUID()
        self.timestamp = Date()
        self.title = title
        self.detail = detail
    }
}

struct HistoryView: View {
    let history: [HistoryItem]
    let onSelect: (HistoryItem) -> Void
    let onClear: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("History")
                    .font(.headline)
                Spacer()
                Button("Clear", action: onClear)
                    .font(.caption)
                    .disabled(history.isEmpty)
            }
            .padding(.horizontal)

            if history.isEmpty {
                ContentUnavailableView("No History", systemImage: "clock", description: Text("Your activity will appear here."))
                    .frame(height: 200)
            } else {
                List {
                    ForEach(history) { item in
                        Button {
                            onSelect(item)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.subheadline.bold())
                                Text(item.detail)
                                    .font(.caption)
                                    .lineLimit(2)
                                    .foregroundStyle(.secondary)
                                Text(item.timestamp, style: .relative)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .frame(height: 300)
            }
        }
    }
}

struct ExportPanel: View {
    let content: String
    let filename: String

    var body: some View {
        HStack {
            Button {
                UIPasteboard.general.string = content
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            .buttonStyle(.bordered)

            Button {
                exportToFile()
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.bordered)
        }
    }

    private func exportToFile() {
        // Implementation for file export
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)
        try? content.write(to: fileURL, atomically: true, encoding: .utf8)
        // In a real app, this would trigger a ShareSheet or DocumentPicker
    }
}

struct JSONView: View {
    let json: String

    var body: some View {
        ScrollView {
            Text(json)
                .font(.system(.caption2, design: .monospaced))
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
        .background(Color(uiColor: .systemGray6))
        .cornerRadius(8)
    }
}

struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(.white)
            .background(color)
            .cornerRadius(4)
    }
}

// MARK: - Protocols & Base Classes

protocol DevToolViewModel: ObservableObject {
    associatedtype State
    var state: State { get }
}

@MainActor
class BaseDevToolViewModel<State>: ObservableObject {
    @Published var state: State

    init(initialState: State) {
        self.state = initialState
    }
}

struct UsageChart: View {
    let data: [Double]

    var body: some View {
        GeometryReader { geo in
            Path { path in
                guard data.count > 1 else { return }
                let step = geo.size.width / CGFloat(data.count - 1)
                let height = geo.size.height

                path.move(to: CGPoint(x: 0, y: height * (1 - CGFloat((data.first ?? 0)/100))))

                for i in 1..<data.count {
                    path.addLine(to: CGPoint(x: CGFloat(i) * step, y: height * (1 - CGFloat(data[i]/100))))
                }
            }
            .stroke(Color.accentColor, lineWidth: 2)
        }
    }
}
