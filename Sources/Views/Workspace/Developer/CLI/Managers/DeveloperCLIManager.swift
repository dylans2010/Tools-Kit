import SwiftUI

@MainActor
public class DeveloperCLIManager: ObservableObject {
    public static let shared = DeveloperCLIManager()

    @Published public var output: [CLIOutput] = []
    @Published public var history: [String] = []
    @Published public var currentTheme: CLITheme = .classic

    private var commands: [String: CLICommand] = [:]

    private init() {
        registerCommands()
        output.append(CLIOutput(text: "Developer Environment CLI v1.0.0", type: .info))
        output.append(CLIOutput(text: "Type 'help' to see available commands.", type: .info))
    }

    private func registerCommands() {
        AppCLIManager.shared.getCommands().forEach { commands[$0.name] = $0 }
        SecurityCLIManager.shared.getCommands().forEach { commands[$0.name] = $0 }
        OpsCLIManager.shared.getCommands().forEach { commands[$0.name] = $0 }
        ResourceCLIManager.shared.getCommands().forEach { commands[$0.name] = $0 }
        registerSystemCommands()
    }

    private func registerSystemCommands() {
        let systemCommands = [
            CLICommand(name: "help", description: "List all commands or get help for a specific command", category: .system, usage: "help [command]", action: { args in
                if let cmdName = args.first {
                    if let cmd = self.commands[cmdName] {
                        return "Help for \(cmd.name):\nDescription: \(cmd.description)\nUsage: \(cmd.usage)"
                    } else {
                        return "Command '\(cmdName)' not found."
                    }
                }
                let grouped = Dictionary(grouping: self.commands.values, by: { $0.category })
                var result = "Available commands:\n"
                for category in CLICommandCategory.allCases {
                    if let cmds = grouped[category] {
                        result += "\n[\(category.rawValue)]\n"
                        result += cmds.map { "  \($0.name.padding(toLength: 20, withPad: " ", startingAt: 0)) - \($0.description)" }.sorted().joined(separator: "\n")
                        result += "\n"
                    }
                }
                return result
            }),

            CLICommand(name: "clear", description: "Clear terminal output", category: .system, usage: "clear", action: { _ in
                self.output.removeAll()
                return ""
            }),

            CLICommand(name: "theme", description: "Change terminal theme", category: .system, usage: "theme <name>", action: { args in
                guard let themeName = args.first?.lowercased() else {
                    return "Available themes: \(CLITheme.themes.map { $0.id }.joined(separator: ", "))"
                }
                if let theme = CLITheme.themes.first(where: { $0.id == themeName }) {
                    self.currentTheme = theme
                    return "Theme changed to \(theme.name)"
                }
                return "Theme '\(themeName)' not found."
            }),

            CLICommand(name: "history", description: "Show command history", category: .system, usage: "history", action: { _ in
                if self.history.isEmpty { return "No history." }
                return self.history.enumerated().map { "\($1)" }.joined(separator: "\n")
            }),

            CLICommand(name: "date", description: "Show current date and time", category: .system, usage: "date", action: { _ in
                return Date().description
            }),

            CLICommand(name: "whoami", description: "Show current developer profile", category: .system, usage: "whoami", action: { _ in
                let profile = DeveloperProfileService.shared.profile
                return "Username: \(profile.username)\nDisplay Name: \(profile.displayName)\nTier: \(profile.tier.rawValue)"
            }),

            CLICommand(name: "version", description: "Show CLI version", category: .system, usage: "version", action: { _ in
                return "Developer CLI v1.0.0"
            }),

            CLICommand(name: "man", description: "Display manual for a command", category: .system, usage: "man <command>", action: { args in
                guard let cmdName = args.first else { return "Usage: man <command>" }
                if let cmd = self.commands[cmdName] {
                    return "MANUAL: \(cmd.name)\n\nDESCRIPTION:\n\(cmd.description)\n\nUSAGE:\n\(cmd.usage)\n\nCATEGORY:\n\(cmd.category.rawValue)"
                }
                return "No manual entry for \(cmdName)"
            }),

            CLICommand(name: "echo", description: "Print text to terminal", category: .system, usage: "echo <text>", action: { args in
                return args.joined(separator: " ")
            }),

            CLICommand(name: "exit", description: "Exit the CLI", category: .system, usage: "exit", action: { _ in
                return "Use the UI to navigate back."
            }),

            CLICommand(name: "pwd", description: "Show current working directory", category: .system, usage: "pwd", action: { _ in
                return "/workspace/developer/cli"
            }),

            CLICommand(name: "ls", description: "List files in current directory", category: .system, usage: "ls", action: { _ in
                return "Managers/  CLIModels.swift  DeveloperCLIView.swift"
            }),

            CLICommand(name: "uptime", description: "Show how long the environment has been running", category: .system, usage: "uptime", action: { _ in
                return "up 2 hours"
            }),

            CLICommand(name: "motd", description: "Show message of the day", category: .system, usage: "motd", action: { _ in
                return "Welcome to the Developer Environment!"
            }),

            CLICommand(name: "sysinfo", description: "Show system information", category: .system, usage: "sysinfo", action: { _ in
                let info = ProcessInfo.processInfo
                return "OS: iOS \(info.operatingSystemVersionString)\nProcessor Count: \(info.processorCount)"
            })
        ]

        systemCommands.forEach { commands[$0.name] = $0 }
    }

    public func execute(_ input: String) async {
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else { return }

        output.append(CLIOutput(text: trimmedInput, type: .command))
        history.append(trimmedInput)

        let parts = trimmedInput.components(separatedBy: .whitespaces)
        let cmdName = parts[0].lowercased()
        let args = Array(parts.dropFirst())

        if let cmd = commands[cmdName] {
            let result = await cmd.action(args)
            if !result.isEmpty {
                output.append(CLIOutput(text: result, type: .result))
            }
        } else {
            output.append(CLIOutput(text: "Command not found: \(cmdName)", type: .error))
        }
    }

    public func getAllCommandOptions() -> [CLICommandOption] {
        return commands.values.map {
            CLICommandOption(name: $0.name, description: $0.description, category: $0.category)
        }.sorted(by: { $0.name < $1.name })
    }
}
