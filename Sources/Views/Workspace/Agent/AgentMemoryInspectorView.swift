import SwiftUI

struct AgentMemoryInspectorView: View {
    @ObservedObject var state: AgentSessionState
    @State private var searchText = ""

    var body: some View {
        List {
            if state.memory.isEmpty {
                ContentUnavailableView(
                    "No Stored Memory",
                    systemImage: "brain",
                    description: Text("Memory entries will appear here once the agent saves information.")
                )
            } else {
                let categories = Array(Set(state.memory.values.compactMap { $0.category ?? "General" })).sorted()

                ForEach(categories, id: \.self) { category in
                    Section {
                        let filteredEntries = state.memory.values
                            .filter { ($0.category ?? "General") == category }
                            .filter { searchText.isEmpty || $0.key.localizedCaseInsensitiveContains(searchText) }
                            .sorted { $0.key < $1.key }

                        ForEach(filteredEntries) { entry in
                            MemoryEntryRow(entry: entry)
                        }
                    } header: {
                        Text(category)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Memory Inspector")
        .searchable(text: $searchText, prompt: "Search memory keys")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    // Manual refresh handled by session manager
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
    }
}

struct MemoryEntryRow: View {
    let entry: AgentMemoryEntry
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.key)
                    .font(.subheadline.bold())
                Spacer()
                Button {
                    withAnimation { isExpanded.toggle() }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    if let jsonString = prettyPrint(entry.value) {
                        Text(jsonString)
                            .font(.system(.caption, design: .monospaced))
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(4)
                    }
                }
                .transition(.opacity)
            } else {
                Text(summary(for: entry.value))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }

    private func summary(for value: AnyCodable) -> String {
        if let string = value.value as? String { return string }
        if let bool = value.value as? Bool { return String(bool) }
        if let int = value.value as? Int { return String(int) }
        if let double = value.value as? Double { return String(double) }
        return "Complex Data"
    }

    private func prettyPrint(_ value: AnyCodable) -> String? {
        do {
            let data = try JSONEncoder().encode(value)
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            let prettyData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
            return String(data: prettyData, encoding: .utf8)
        } catch {
            return nil
        }
    }
}
