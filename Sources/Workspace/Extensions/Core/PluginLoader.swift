import Foundation

/// Handles persistent storage and loading of plugins.
final class PluginLoader {
    private let storageFile = "plugins_v2.json"
    private let logsFile = "plugin_logs.json"

    /// Loads all installed and user-created plugins.
    func loadPlugins() -> [Plugin] {
        if WorkspacePersistence.shared.exists(filename: storageFile) {
            return (try? WorkspacePersistence.shared.load([Plugin].self, from: storageFile)) ?? []
        }
        return seedDefaultPlugins()
    }

    /// Saves the current list of plugins.
    func savePlugins(_ plugins: [Plugin]) {
        try? WorkspacePersistence.shared.save(plugins, to: storageFile)
    }

    /// Loads execution logs.
    func loadLogs() -> [PluginExecutionLog] {
        if WorkspacePersistence.shared.exists(filename: logsFile) {
            return (try? WorkspacePersistence.shared.load([PluginExecutionLog].self, from: logsFile)) ?? []
        }
        return []
    }

    /// Saves execution logs.
    func saveLogs(_ logs: [PluginExecutionLog]) {
        try? WorkspacePersistence.shared.save(logs, to: logsFile)
    }

    private func seedDefaultPlugins() -> [Plugin] {
        let noteSummaryPlugin = Plugin(
            id: UUID(),
            identifier: "com.ToolsKit.NoteSummarizer",
            name: "Auto Note Summarizer",
            description: "Automatically generates a summary when a note is created.",
            icon: "doc.text.magnifyingglass",
            version: "1.0.0",
            author: "ToolsKit Team",
            capabilities: [.notes, .ai],
            actions: [.noteCreated],
            commands: [],
            permissions: [.readNotes, .writeNotes, .aiGenerate],
            sourceCode: """
            export function onEvent(event, ctx) {
                if (event.type === 'note.created') {
                    const content = event.payload.content || '';
                    const summary = ctx.ai.summarize(content);
                    ctx.notes.update(event.payload.id, summary);
                    return 'Summarized note ' + event.payload.id;
                }
            }
            """,
            isEnabled: true,
            isInstalled: true,
            isUserCreated: false,
            createdAt: Date()
        )

        let taskNotifierPlugin = Plugin(
            id: UUID(),
            identifier: "com.ToolsKit.TaskNotifier",
            name: "Task Completion Mailer",
            description: "Sends a mail notification when a task is completed.",
            icon: "envelope.badge.shield.half.filled",
            version: "1.0.0",
            author: "ToolsKit Team",
            capabilities: [.tasks, .mail],
            actions: [.taskCompleted],
            commands: [],
            permissions: [.readTasks, .writeMail],
            sourceCode: """
            export function onEvent(event, ctx) {
                if (event.type === 'task.completed') {
                    const title = event.payload.title || 'Untitled Task';
                    ctx.mail.send('user@example.com', 'Task Completed', 'The task "' + title + '" has been marked as finished.');
                    return 'Sent notification for: ' + title;
                }
            }
            """,
            isEnabled: true,
            isInstalled: true,
            isUserCreated: false,
            createdAt: Date()
        )

        return [noteSummaryPlugin, taskNotifierPlugin]
    }
}
