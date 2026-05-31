import Foundation

@MainActor
public class AppCLIManager {
    public static let shared = AppCLIManager()
    private let appService = DeveloperAppService.shared

    private init() {}

    public func getCommands() -> [CLICommand] {
        var commands: [CLICommand] = []

        // --- Apps (25 commands) ---
        commands.append(CLICommand(name: "apps:list", description: "List all registered applications", category: .apps, usage: "apps:list", action: { _ in
            let apps = self.appService.apps
            if apps.isEmpty { return "No applications found." }
            return apps.map { "[\($0.status.rawValue)] \($0.name) (\($0.id)) - v\($0.version)" }.joined(separator: "\n")
        }))

        commands.append(CLICommand(name: "apps:count", description: "Get the total number of applications", category: .apps, usage: "apps:count", action: { _ in
            return "Total apps: \(self.appService.apps.count)"
        }))

        commands.append(CLICommand(name: "apps:live", description: "List all live applications", category: .apps, usage: "apps:live", action: { _ in
            let apps = self.appService.apps.filter { $0.status == .live }
            if apps.isEmpty { return "No live applications found." }
            return apps.map { "\($0.name) (\($0.id))" }.joined(separator: "\n")
        }))

        commands.append(CLICommand(name: "apps:drafts", description: "List all draft applications", category: .apps, usage: "apps:drafts", action: { _ in
            let apps = self.appService.apps.filter { $0.status == .draft }
            if apps.isEmpty { return "No draft applications found." }
            return apps.map { "\($0.name) (\($0.id))" }.joined(separator: "\n")
        }))

        commands.append(CLICommand(name: "apps:inspect", description: "View detailed information about an app", category: .apps, usage: "apps:inspect <app_id>", action: { args in
            guard let idStr = args.first, let id = UUID(uuidString: idStr) else { return "Usage: apps:inspect <app_id>" }
            guard let app = self.appService.apps.first(where: { $0.id == id }) else { return "App not found." }
            return """
            Name: \(app.name)
            ID: \(app.id)
            Status: \(app.status.rawValue)
            Version: \(app.version)
            Bundle ID: \(app.bundleId)
            Type: \(app.type.rawValue)
            Created: \(app.createdAt)
            Last Modified: \(app.lastModified)
            Installs: \(app.installCount)
            """
        }))

        commands.append(CLICommand(name: "apps:create", description: "Create a new application", category: .apps, usage: "apps:create <name> <type>", action: { args in
            guard args.count >= 2 else { return "Usage: apps:create <name> <type> (App, Plugin, Connector, Service, SDK Extension)" }
            let name = args[0]
            guard let type = DeveloperAppType(rawValue: args[1]) else { return "Invalid type." }
            let app = DeveloperApp(name: name, type: type)
            try? await self.appService.createApp(app)
            return "Successfully created app: \(name) (\(app.id))"
        }))

        commands.append(CLICommand(name: "apps:delete", description: "Delete an application", category: .apps, usage: "apps:delete <app_id>", action: { args in
            guard let idStr = args.first, let id = UUID(uuidString: idStr) else { return "Usage: apps:delete <app_id>" }
            try? await self.appService.deleteApp(id: id)
            return "Successfully deleted app: \(idStr)"
        }))

        commands.append(CLICommand(name: "apps:rename", description: "Rename an application", category: .apps, usage: "apps:rename <app_id> <new_name>", action: { args in
            guard args.count >= 2, let id = UUID(uuidString: args[0]) else { return "Usage: apps:rename <app_id> <new_name>" }
            guard var app = self.appService.apps.first(where: { $0.id == id }) else { return "App not found." }
            app.name = args[1]
            try? await self.appService.updateApp(app)
            return "App \(id) renamed to \(args[1])"
        }))

        commands.append(CLICommand(name: "apps:status", description: "Update app status", category: .apps, usage: "apps:status <app_id> <Live|Draft|Suspended|Archived>", action: { args in
            guard args.count >= 2, let id = UUID(uuidString: args[0]) else { return "Usage: apps:status <app_id> <status>" }
            guard let status = DeveloperAppStatus(rawValue: args[1]) else { return "Invalid status." }
            try? await self.appService.transitionStatus(id: id, newStatus: status, reason: "CLI update")
            return "App \(id) status updated to \(status.rawValue)"
        }))

        commands.append(CLICommand(name: "apps:bundle", description: "Update app bundle ID", category: .apps, usage: "apps:bundle <app_id> <bundle_id>", action: { args in
            guard args.count >= 2, let id = UUID(uuidString: args[0]) else { return "Usage: apps:bundle <app_id> <bundle_id>" }
            guard var app = self.appService.apps.first(where: { $0.id == id }) else { return "App not found." }
            app.bundleId = args[1]
            try? await self.appService.updateApp(app)
            return "App \(id) bundle ID updated to \(args[1])"
        }))

        commands.append(CLICommand(name: "apps:desc", description: "Update app description", category: .apps, usage: "apps:desc <app_id> <description>", action: { args in
            guard args.count >= 2, let id = UUID(uuidString: args[0]) else { return "Usage: apps:desc <app_id> <description>" }
            guard var app = self.appService.apps.first(where: { $0.id == id }) else { return "App not found." }
            app.description = args.dropFirst().joined(separator: " ")
            try? await self.appService.updateApp(app)
            return "App \(id) description updated."
        }))

        commands.append(CLICommand(name: "apps:monetization", description: "Update app monetization model", category: .apps, usage: "apps:monetization <app_id> <Free|Freemium|Subscription|One-time Purchase>", action: { args in
            guard args.count >= 2, let id = UUID(uuidString: args[0]) else { return "Usage: apps:monetization <app_id> <model>" }
            guard let model = MonetizationModel(rawValue: args[1]) else { return "Invalid model." }
            guard var app = self.appService.apps.first(where: { $0.id == id }) else { return "App not found." }
            app.monetizationModel = model
            try? await self.appService.updateApp(app)
            return "App \(id) monetization updated to \(model.rawValue)"
        }))

        commands.append(CLICommand(name: "apps:transfer", description: "Transfer app ownership", category: .apps, usage: "apps:transfer <app_id> <email>", action: { args in
            guard args.count >= 2, let id = UUID(uuidString: args[0]) else { return "Usage: apps:transfer <app_id> <email>" }
            try? await self.appService.transferOwnership(appID: id, toEmail: args[1])
            return "Ownership transfer initiated for \(id) to \(args[1])"
        }))

        commands.append(CLICommand(name: "apps:type", description: "Change app type", category: .apps, usage: "apps:type <app_id> <type>", action: { args in
            guard args.count >= 2, let id = UUID(uuidString: args[0]) else { return "Usage: apps:type <app_id> <type>" }
            guard let type = DeveloperAppType(rawValue: args[1]) else { return "Invalid type." }
            guard var app = self.appService.apps.first(where: { $0.id == id }) else { return "App not found." }
            app.type = type
            try? await self.appService.updateApp(app)
            return "App \(id) type updated to \(type.rawValue)"
        }))

        commands.append(CLICommand(name: "apps:installs", description: "Get install count", category: .apps, usage: "apps:installs <app_id>", action: { args in
            guard let id = UUID(uuidString: args.first ?? "") else { return "Usage: apps:installs <app_id>" }
            guard let app = self.appService.apps.first(where: { $0.id == id }) else { return "App not found." }
            return "App \(app.name) has \(app.installCount) installs."
        }))

        commands.append(CLICommand(name: "apps:search", description: "Search apps by name", category: .apps, usage: "apps:search <query>", action: { args in
            let query = args.joined(separator: " ").lowercased()
            let filtered = self.appService.apps.filter { $0.name.lowercased().contains(query) }
            if filtered.isEmpty { return "No matches found." }
            return filtered.map { "\($0.name) (\($0.id))" }.joined(separator: "\n")
        }))

        commands.append(CLICommand(name: "apps:archive", description: "Archive an app", category: .apps, usage: "apps:archive <app_id>", action: { args in
            guard let id = UUID(uuidString: args.first ?? "") else { return "Usage: apps:archive <app_id>" }
            try? await self.appService.transitionStatus(id: id, newStatus: .archived, reason: "CLI Archive")
            return "App archived."
        }))

        commands.append(CLICommand(name: "apps:deprecate", description: "Deprecate an app", category: .apps, usage: "apps:deprecate <app_id>", action: { args in
            guard let id = UUID(uuidString: args.first ?? "") else { return "Usage: apps:deprecate <app_id>" }
            try? await self.appService.transitionStatus(id: id, newStatus: .deprecated, reason: "CLI Deprecation")
            return "App deprecated."
        }))

        commands.append(CLICommand(name: "apps:suspend", description: "Suspend an app", category: .apps, usage: "apps:suspend <app_id>", action: { args in
            guard let id = UUID(uuidString: args.first ?? "") else { return "Usage: apps:suspend <app_id>" }
            try? await self.appService.transitionStatus(id: id, newStatus: .suspended, reason: "CLI Suspension")
            return "App suspended."
        }))

        commands.append(CLICommand(name: "apps:live:count", description: "Count live apps", category: .apps, usage: "apps:live:count", action: { _ in
            return "Live apps: \(self.appService.apps.filter { $0.status == .live }.count)"
        }))

        commands.append(CLICommand(name: "apps:latest", description: "Get most recently created app", category: .apps, usage: "apps:latest", action: { _ in
            guard let app = self.appService.apps.sorted(by: { $0.createdAt > $1.createdAt }).first else { return "No apps." }
            return "Latest: \(app.name) (\(app.createdAt))"
        }))

        commands.append(CLICommand(name: "apps:oldest", description: "Get oldest app", category: .apps, usage: "apps:oldest", action: { _ in
            guard let app = self.appService.apps.sorted(by: { $0.createdAt < $1.createdAt }).first else { return "No apps." }
            return "Oldest: \(app.name) (\(app.createdAt))"
        }))

        commands.append(CLICommand(name: "apps:export", description: "Export app configuration as JSON string", category: .apps, usage: "apps:export <app_id>", action: { args in
            guard let id = UUID(uuidString: args.first ?? "") else { return "Usage: apps:export <app_id>" }
            guard let app = self.appService.apps.first(where: { $0.id == id }) else { return "App not found." }
            let data = try? JSONEncoder().encode(app)
            return data.flatMap { String(data: $0, encoding: .utf8) } ?? "Export failed."
        }))

        commands.append(CLICommand(name: "apps:credits", description: "Update app credits", category: .apps, usage: "apps:credits <app_id> <credits>", action: { args in
            guard args.count >= 2, let id = UUID(uuidString: args[0]) else { return "Usage: apps:credits <app_id> <credits>" }
            guard var app = self.appService.apps.first(where: { $0.id == id }) else { return "App not found." }
            app.credits = args.dropFirst().joined(separator: " ")
            try? await self.appService.updateApp(app)
            return "App \(id) credits updated."
        }))

        commands.append(CLICommand(name: "apps:icon", description: "Update app icon name", category: .apps, usage: "apps:icon <app_id> <sf_symbol>", action: { args in
            guard args.count >= 2, let id = UUID(uuidString: args[0]) else { return "Usage: apps:icon <app_id> <sf_symbol>" }
            guard var app = self.appService.apps.first(where: { $0.id == id }) else { return "App not found." }
            app.iconName = args[1]
            try? await self.appService.updateApp(app)
            return "App \(id) icon updated."
        }))

        // --- Versions (10 commands) ---
        commands.append(CLICommand(name: "versions:list", description: "List all versions of an app", category: .apps, usage: "versions:list <app_id>", action: { args in
            guard let id = UUID(uuidString: args.first ?? "") else { return "Usage: versions:list <app_id>" }
            guard let app = self.appService.apps.first(where: { $0.id == id }) else { return "App not found." }
            if app.versions.isEmpty { return "No versions found." }
            return app.versions.map { "[\($0.status)] v\($0.version) (\($0.buildNumber))" }.joined(separator: "\n")
        }))

        commands.append(CLICommand(name: "versions:add", description: "Add a new version to an app", category: .apps, usage: "versions:add <app_id> <version> <build>", action: { args in
            guard args.count >= 3, let id = UUID(uuidString: args[0]) else { return "Usage: versions:add <app_id> <version> <build>" }
            let ver = AppVersion(version: args[1], buildNumber: args[2])
            try? await self.appService.addVersion(appID: id, version: ver)
            return "Version \(args[1]) added to \(id)"
        }))

        commands.append(CLICommand(name: "versions:promote", description: "Promote a version to Released status", category: .apps, usage: "versions:promote <app_id> <version_id>", action: { args in
            guard args.count >= 2, let appID = UUID(uuidString: args[0]), let verID = UUID(uuidString: args[1]) else { return "Usage: versions:promote <app_id> <version_id>" }
            guard var app = self.appService.apps.first(where: { $0.id == appID }) else { return "App not found." }
            if let idx = app.versions.firstIndex(where: { $0.id == verID }) {
                app.versions[idx].status = "Released"
                app.version = app.versions[idx].version
                try? await self.appService.updateApp(app)
                return "Version promoted."
            }
            return "Version not found."
        }))

        commands.append(CLICommand(name: "versions:rollout", description: "Update rollout percentage", category: .apps, usage: "versions:rollout <app_id> <version_id> <0-100>", action: { args in
            guard args.count >= 3, let appID = UUID(uuidString: args[0]), let verID = UUID(uuidString: args[1]), let pct = Double(args[2]) else { return "Usage: versions:rollout <app_id> <version_id> <0-100>" }
            guard var app = self.appService.apps.first(where: { $0.id == appID }) else { return "App not found." }
            if let idx = app.versions.firstIndex(where: { $0.id == verID }) {
                app.versions[idx].rolloutPercentage = pct
                try? await self.appService.updateApp(app)
                return "Rollout set to \(pct)%."
            }
            return "Version not found."
        }))

        commands.append(CLICommand(name: "versions:notes", description: "Update release notes", category: .apps, usage: "versions:notes <app_id> <version_id> <notes>", action: { args in
            guard args.count >= 3, let appID = UUID(uuidString: args[0]), let verID = UUID(uuidString: args[1]) else { return "Usage: versions:notes <app_id> <version_id> <notes>" }
            guard var app = self.appService.apps.first(where: { $0.id == appID }) else { return "App not found." }
            if let idx = app.versions.firstIndex(where: { $0.id == verID }) {
                app.versions[idx].releaseNotes = args.dropFirst(2).joined(separator: " ")
                try? await self.appService.updateApp(app)
                return "Release notes updated."
            }
            return "Version not found."
        }))

        commands.append(CLICommand(name: "versions:delete", description: "Remove a version", category: .apps, usage: "versions:delete <app_id> <version_id>", action: { args in
            guard args.count >= 2, let appID = UUID(uuidString: args[0]), let verID = UUID(uuidString: args[1]) else { return "Usage: versions:delete <app_id> <version_id>" }
            guard var app = self.appService.apps.first(where: { $0.id == appID }) else { return "App not found." }
            app.versions.removeAll { $0.id == verID }
            try? await self.appService.updateApp(app)
            return "Version deleted."
        }))

        commands.append(CLICommand(name: "versions:latest", description: "Show latest version info", category: .apps, usage: "versions:latest <app_id>", action: { args in
            guard let id = UUID(uuidString: args.first ?? "") else { return "Usage: versions:latest <app_id>" }
            guard let app = self.appService.apps.first(where: { $0.id == id }) else { return "App not found." }
            guard let ver = app.versions.sorted(by: { $0.createdAt > $1.createdAt }).first else { return "No versions." }
            return "Latest Version: \(ver.version) (\(ver.status))"
        }))

        commands.append(CLICommand(name: "versions:count", description: "Count versions of an app", category: .apps, usage: "versions:count <app_id>", action: { args in
            guard let id = UUID(uuidString: args.first ?? "") else { return "Usage: versions:count <app_id>" }
            guard let app = self.appService.apps.first(where: { $0.id == id }) else { return "App not found." }
            return "App \(app.name) has \(app.versions.count) versions."
        }))

        commands.append(CLICommand(name: "versions:active", description: "Show current live version", category: .apps, usage: "versions:active <app_id>", action: { args in
            guard let id = UUID(uuidString: args.first ?? "") else { return "Usage: versions:active <app_id>" }
            guard let app = self.appService.apps.first(where: { $0.id == id }) else { return "App not found." }
            return "Current Live Version: \(app.version)"
        }))

        commands.append(CLICommand(name: "versions:builds", description: "List all build numbers for an app", category: .apps, usage: "versions:builds <app_id>", action: { args in
            guard let id = UUID(uuidString: args.first ?? "") else { return "Usage: versions:builds <app_id>" }
            guard let app = self.appService.apps.first(where: { $0.id == id }) else { return "App not found." }
            return app.versions.map { $0.buildNumber }.joined(separator: ", ")
        }))

        // --- Collaborators (8 commands) ---
        commands.append(CLICommand(name: "collab:list", description: "List all collaborators for an app", category: .apps, usage: "collab:list <app_id>", action: { args in
            guard let id = UUID(uuidString: args.first ?? "") else { return "Usage: collab:list <app_id>" }
            guard let app = self.appService.apps.first(where: { $0.id == id }) else { return "App not found." }
            if app.collaborators.isEmpty { return "No collaborators." }
            return app.collaborators.map { "\($0.name) (\($0.role)) - \($0.email)" }.joined(separator: "\n")
        }))

        commands.append(CLICommand(name: "collab:add", description: "Add a collaborator", category: .apps, usage: "collab:add <app_id> <email> <role>", action: { args in
            guard args.count >= 3, let id = UUID(uuidString: args[0]) else { return "Usage: collab:add <app_id> <email> <role>" }
            let collab = AppCollaborator(accountID: UUID(), name: args[1].components(separatedBy: "@").first ?? "User", email: args[1], role: args[2])
            try? await self.appService.addCollaborator(appID: id, collaborator: collab)
            return "Collaborator \(args[1]) added."
        }))

        commands.append(CLICommand(name: "collab:remove", description: "Remove a collaborator", category: .apps, usage: "collab:remove <app_id> <collab_id>", action: { args in
            guard args.count >= 2, let appID = UUID(uuidString: args[0]), let collabID = UUID(uuidString: args[1]) else { return "Usage: collab:remove <app_id> <collab_id>" }
            try? await self.appService.removeCollaborator(appID: appID, collaboratorID: collabID)
            return "Collaborator removed."
        }))

        commands.append(CLICommand(name: "collab:role", description: "Update collaborator role", category: .apps, usage: "collab:role <app_id> <collab_id> <role>", action: { args in
            guard args.count >= 3, let appID = UUID(uuidString: args[0]), let collabID = UUID(uuidString: args[1]) else { return "Usage: collab:role <app_id> <collab_id> <role>" }
            guard var app = self.appService.apps.first(where: { $0.id == appID }) else { return "App not found." }
            if let idx = app.collaborators.firstIndex(where: { $0.id == collabID }) {
                app.collaborators[idx].role = args[2]
                try? await self.appService.updateApp(app)
                return "Role updated."
            }
            return "Collaborator not found."
        }))

        commands.append(CLICommand(name: "collab:count", description: "Count collaborators", category: .apps, usage: "collab:count <app_id>", action: { args in
            guard let id = UUID(uuidString: args.first ?? "") else { return "Usage: collab:count <app_id>" }
            guard let app = self.appService.apps.first(where: { $0.id == id }) else { return "App not found." }
            return "Collaborators: \(app.collaborators.count)"
        }))

        commands.append(CLICommand(name: "collab:inspect", description: "Inspect a collaborator", category: .apps, usage: "collab:inspect <app_id> <collab_id>", action: { args in
            guard args.count >= 2, let appID = UUID(uuidString: args[0]), let collabID = UUID(uuidString: args[1]) else { return "Usage: collab:inspect <app_id> <collab_id>" }
            guard let app = self.appService.apps.first(where: { $0.id == appID }) else { return "App not found." }
            guard let collab = app.collaborators.first(where: { $0.id == collabID }) else { return "Collab not found." }
            return "Name: \(collab.name)\nEmail: \(collab.email)\nRole: \(collab.role)\nID: \(collab.id)"
        }))

        commands.append(CLICommand(name: "collab:owners", description: "List app owners", category: .apps, usage: "collab:owners <app_id>", action: { args in
            guard let id = UUID(uuidString: args.first ?? "") else { return "Usage: collab:owners <app_id>" }
            guard let app = self.appService.apps.first(where: { $0.id == id }) else { return "App not found." }
            let owners = app.collaborators.filter { $0.role.lowercased() == "owner" }
            return owners.map { $0.email }.joined(separator: ", ")
        }))

        commands.append(CLICommand(name: "collab:devs", description: "List app developers", category: .apps, usage: "collab:devs <app_id>", action: { args in
            guard let id = UUID(uuidString: args.first ?? "") else { return "Usage: collab:devs <app_id>" }
            guard let app = self.appService.apps.first(where: { $0.id == id }) else { return "App not found." }
            let devs = app.collaborators.filter { $0.role.lowercased() == "developer" }
            return devs.map { $0.email }.joined(separator: ", ")
        }))

        // --- Environments (7 commands) ---
        commands.append(CLICommand(name: "env:list", description: "List all environments for an app", category: .apps, usage: "env:list <app_id>", action: { args in
            guard let id = UUID(uuidString: args.first ?? "") else { return "Usage: env:list <app_id>" }
            guard let app = self.appService.apps.first(where: { $0.id == id }) else { return "App not found." }
            if app.environments.isEmpty { return "No environments." }
            return app.environments.map { "\($0.name): \($0.apiBaseURL)" }.joined(separator: "\n")
        }))

        commands.append(CLICommand(name: "env:add", description: "Add an environment", category: .apps, usage: "env:add <app_id> <name> <url>", action: { args in
            guard args.count >= 3, let id = UUID(uuidString: args[0]) else { return "Usage: env:add <app_id> <name> <url>" }
            guard var app = self.appService.apps.first(where: { $0.id == id }) else { return "App not found." }
            let env = AppEnvironment(name: args[1], apiBaseURL: args[2])
            app.environments.append(env)
            try? await self.appService.updateApp(app)
            return "Environment \(args[1]) added."
        }))

        commands.append(CLICommand(name: "env:remove", description: "Remove an environment", category: .apps, usage: "env:remove <app_id> <env_id>", action: { args in
            guard args.count >= 2, let appID = UUID(uuidString: args[0]), let envID = UUID(uuidString: args[1]) else { return "Usage: env:remove <app_id> <env_id>" }
            guard var app = self.appService.apps.first(where: { $0.id == appID }) else { return "App not found." }
            app.environments.removeAll { $0.id == envID }
            try? await self.appService.updateApp(app)
            return "Environment removed."
        }))

        commands.append(CLICommand(name: "env:url", description: "Update environment URL", category: .apps, usage: "env:url <app_id> <env_id> <new_url>", action: { args in
            guard args.count >= 3, let appID = UUID(uuidString: args[0]), let envID = UUID(uuidString: args[1]) else { return "Usage: env:url <app_id> <env_id> <new_url>" }
            guard var app = self.appService.apps.first(where: { $0.id == appID }) else { return "App not found." }
            if let idx = app.environments.firstIndex(where: { $0.id == envID }) {
                app.environments[idx].apiBaseURL = args[2]
                try? await self.appService.updateApp(app)
                return "Environment URL updated."
            }
            return "Environment not found."
        }))

        commands.append(CLICommand(name: "env:inspect", description: "Inspect an environment", category: .apps, usage: "env:inspect <app_id> <env_id>", action: { args in
            guard args.count >= 2, let appID = UUID(uuidString: args[0]), let envID = UUID(uuidString: args[1]) else { return "Usage: env:inspect <app_id> <env_id>" }
            guard let app = self.appService.apps.first(where: { $0.id == appID }) else { return "App not found." }
            guard let env = app.environments.first(where: { $0.id == envID }) else { return "Env not found." }
            return "Name: \(env.name)\nURL: \(env.apiBaseURL)\nKeys: \(env.assignedKeyIDs.count)\nID: \(env.id)"
        }))

        commands.append(CLICommand(name: "env:count", description: "Count environments", category: .apps, usage: "env:count <app_id>", action: { args in
            guard let id = UUID(uuidString: args.first ?? "") else { return "Usage: env:count <app_id>" }
            guard let app = self.appService.apps.first(where: { $0.id == id }) else { return "App not found." }
            return "Environments: \(app.environments.count)"
        }))

        commands.append(CLICommand(name: "env:keys", description: "List keys assigned to environment", category: .apps, usage: "env:keys <app_id> <env_id>", action: { args in
            guard args.count >= 2, let appID = UUID(uuidString: args[0]), let envID = UUID(uuidString: args[1]) else { return "Usage: env:keys <app_id> <env_id>" }
            guard let app = self.appService.apps.first(where: { $0.id == appID }) else { return "App not found." }
            guard let env = app.environments.first(where: { $0.id == envID }) else { return "Env not found." }
            return "Assigned Key IDs: \(env.assignedKeyIDs.map { $0.uuidString }.joined(separator: ", "))"
        }))

        return commands
    }
}
