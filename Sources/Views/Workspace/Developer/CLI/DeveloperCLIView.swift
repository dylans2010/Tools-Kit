import SwiftUI

struct DeveloperCLIView: View {
    @StateObject private var manager = DeveloperCLIManager.shared
    @State private var input: String = ""
    @State private var showHelp = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            terminalOutput
            terminalPrompt
        }
        .background(manager.currentTheme.backgroundColor)
        .navigationTitle("Developer CLI")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showHelp.toggle() }) {
                    Image(systemName: "list.bullet.rectangle")
                }
            }
        }
        .sheet(isPresented: $showHelp) {
            CLIHelpSheet()
                .presentationDetents([.medium, .large])
        }
        .onAppear {
            isFocused = true
        }
    }

    private var terminalOutput: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(manager.output) { log in
                        HStack(alignment: .top, spacing: 8) {
                            if log.type == .command {
                                Text(">")
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(manager.currentTheme.promptColor)
                            }

                            Text(log.text)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(color(for: log.type))
                                .textSelection(.enabled)
                        }
                        .id(log.id)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .onChange(of: manager.output) { _ in
                if let lastId = manager.output.last?.id {
                    withAnimation {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var terminalPrompt: some View {
        VStack(spacing: 0) {
            Divider().background(manager.currentTheme.textColor.opacity(0.2))

            HStack(spacing: 8) {
                Text("dev@tk:~$")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(manager.currentTheme.promptColor)

                TextField("", text: $input)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(manager.currentTheme.textColor)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($isFocused)
                    .onSubmit {
                        let cmd = input
                        input = ""
                        Task {
                            await manager.execute(cmd)
                        }
                    }
            }
            .padding()
            .background(manager.currentTheme.backgroundColor)
        }
    }

    private func color(for type: CLIOutput.OutputType) -> Color {
        switch type {
        case .command: return manager.currentTheme.textColor
        case .result: return manager.currentTheme.textColor
        case .error: return manager.currentTheme.errorColor
        case .info: return manager.currentTheme.infoColor
        case .success: return manager.currentTheme.successColor
        }
    }
}

struct CLIHelpSheet: View {
    @State private var searchText = ""
    private let options = DeveloperCLIManager.shared.getAllCommandOptions()

    var filteredOptions: [CLICommandOption] {
        if searchText.isEmpty { return options }
        return options.filter {
            $0.name.lowercased().contains(searchText.lowercased()) ||
            $0.description.lowercased().contains(searchText.lowercased())
        }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(CLICommandCategory.allCases) { category in
                    let categoryOptions = filteredOptions.filter { $0.category == category }
                    if !categoryOptions.isEmpty {
                        Section(header: Text(category.rawValue)) {
                            ForEach(categoryOptions) { option in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(option.name)
                                        .font(.system(.subheadline, design: .monospaced))
                                        .fontWeight(.bold)
                                    Text(option.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search commands...")
            .navigationTitle("Command Palette")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
