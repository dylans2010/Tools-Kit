import SwiftUI

// MARK: - Global Command Palette Overlay

struct GlobalCommandPaletteView: View {
    @Binding var isPresented: Bool
    @StateObject private var engine = CommandEngine.shared
    @State private var query = ""
    @State private var suggestions: [CommandSuggestion] = []
    @State private var lastResult: CommandResult?
    @State private var showingResult = false
    @FocusState private var isInputFocused: Bool

    var currentView: String = ""

    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: UIScreen.main.bounds.height * 0.15)

                VStack(spacing: 0) {
                    // Input
                    HStack(spacing: 10) {
                        Image(systemName: "command")
                            .foregroundStyle(.blue)
                            .font(.title3)
                        TextField("Type a command…", text: $query)
                            .focused($isInputFocused)
                            .font(.title3)
                            .onSubmit { executeQuery() }
                            .onChange(of: query) { _, new in
                                suggestions = engine.suggestions(for: new)
                            }
                        if !query.isEmpty {
                            Button(action: { query = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Button(action: dismiss) {
                            Image(systemName: "keyboard.chevron.compact.down")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(14)
                    .background(Color(uiColor: .systemBackground))

                    Divider()

                    // Result Banner
                    if let result = lastResult, showingResult {
                        HStack {
                            Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(result.success ? .green : .red)
                            Text(result.output)
                                .font(.caption)
                                .lineLimit(2)
                            Spacer()
                            Button(action: { showingResult = false }) {
                                Image(systemName: "xmark").font(.caption2)
                            }
                        }
                        .padding(10)
                        .background(Color(uiColor: .secondarySystemBackground))

                        Divider()
                    }

                    // Suggestions
                    let displaySuggestions = query.isEmpty ? engine.contextSuggestions(currentView: currentView) : suggestions
                    if !displaySuggestions.isEmpty {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(displaySuggestions) { suggestion in
                                    SuggestionRow(suggestion: suggestion) {
                                        query = suggestion.text
                                        executeQuery()
                                    }
                                    Divider().padding(.leading, 52)
                                }
                            }
                        }
                        .frame(maxHeight: 320)
                        .background(Color(uiColor: .systemBackground))
                    }

                    // History
                    if query.isEmpty && !engine.history.isEmpty {
                        Divider()
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Recent")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 14)
                                .padding(.top, 8)

                            ForEach(engine.history.prefix(5)) { result in
                                Button(action: {
                                    query = result.command
                                    executeQuery()
                                }) {
                                    HStack {
                                        Image(systemName: "clock")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .frame(width: 24)
                                        Text(result.command)
                                            .font(.subheadline)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        Text(result.timestamp, style: .relative)
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .background(Color(uiColor: .systemBackground))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 8)
                .padding(.horizontal, 16)

                Spacer()
            }
        }
        .onAppear {
            isInputFocused = true
            suggestions = engine.contextSuggestions(currentView: currentView)
        }
    }

    private func executeQuery() {
        guard !query.isEmpty else { return }
        let result = engine.execute(query)
        lastResult = result
        showingResult = true
        query = ""
        suggestions = engine.contextSuggestions(currentView: currentView)
    }

    private func dismiss() {
        query = ""
        lastResult = (nil as CommandResult?)
        showingResult = false
        isPresented = false
    }
}

// MARK: - Suggestion Row

struct SuggestionRow: View {
    let suggestion: CommandSuggestion
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: suggestion.icon)
                    .font(.subheadline)
                    .foregroundStyle(.blue)
                    .frame(width: 28, height: 28)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 2) {
                    Text(suggestion.text).font(.subheadline)
                    Text(suggestion.description).font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "return").font(.caption2).foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Command Palette Button (toolbar shortcut)

struct CommandPaletteButton: View {
    @Binding var isShowingPalette: Bool

    var body: some View {
        Button(action: { isShowingPalette = true }) {
            Image(systemName: "magnifyingglass.circle.fill")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.blue)
        }
    }
}

// MARK: - Command History View

struct CommandHistoryView: View {
    @StateObject private var engine = CommandEngine.shared

    var body: some View {
        List {
            if engine.history.isEmpty {
                Text("No commands executed yet.").foregroundStyle(.secondary).font(.caption)
            } else {
                ForEach(engine.history) { result in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(result.success ? .green : .red)
                                .font(.caption)
                            Text(result.command).font(.subheadline.bold())
                            Spacer()
                            Text(result.timestamp, style: .relative).font(.caption2).foregroundStyle(.secondary)
                        }
                        Text(result.output)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Command History")
    }
}
