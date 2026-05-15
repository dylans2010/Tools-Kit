import SwiftUI

struct CommandPaletteView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    let actions: [CommandAction] = [
        CommandAction(title: "Add Text Block", icon: "text.alignleft", color: .blue, category: "Blocks"),
        CommandAction(title: "Add Code Block", icon: "chevron.left.forwardslash.chevron.right", color: .orange, category: "Blocks"),
        CommandAction(title: "Add Database", icon: "tablecells", color: .green, category: "Blocks"),
        CommandAction(title: "Summarize Page", icon: "sparkles", color: .purple, category: "AI"),
        CommandAction(title: "Generate Tags", icon: "tag.fill", color: .teal, category: "AI"),
        CommandAction(title: "Export to PDF", icon: "doc.arrow.up", color: .red, category: "Actions"),
        CommandAction(title: "Share Page", icon: "square.and.arrow.up", color: .blue, category: "Actions")
    ]

    var filteredActions: [CommandAction] {
        if searchText.isEmpty { return actions }
        return actions.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Type a command or search...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))

                List {
                    ForEach(groupedActions.keys.sorted(), id: \.self) { category in
                        Section {
                            ForEach(groupedActions[category] ?? []) { action in
                                Button {
                                    // Execute action
                                    dismiss()
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: action.icon)
                                            .foregroundStyle(action.color)
                                            .frame(width: 24)
                                        Text(action.title)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        Text(action.shortcut)
                                            .font(.caption2.monospaced())
                                            .foregroundStyle(.secondary)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 4))
                                    }
                                }
                            }
                        } header: {
                            Text(category)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Command Palette")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var groupedActions: [String: [CommandAction]] {
        Dictionary(grouping: filteredActions, by: { $0.category })
    }
}

struct CommandAction: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let category: String
    var shortcut: String = "⌘K"
}
