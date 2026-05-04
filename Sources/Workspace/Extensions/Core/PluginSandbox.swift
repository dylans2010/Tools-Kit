import Foundation
import JavaScriptCore

// MARK: - SDK Protocols

@objc protocol NotesJSExport: JSExport {
    func create(_ content: String) -> String
    func update(_ id: String, _ content: String)
    func delete(_ id: String)
}

@objc protocol MailJSExport: JSExport {
    func send(_ to: String, _ subject: String, _ body: String)
}

@objc protocol TasksJSExport: JSExport {
    func create(_ title: String) -> String
    func complete(_ id: String)
}

@objc protocol CalendarJSExport: JSExport {
    func createEvent(_ title: String, _ dateISO: String) -> String
}

@objc protocol FilesJSExport: JSExport {
    func listFiles() -> [String]
    func readFile(_ path: String) -> String
}

@objc protocol AIJSExport: JSExport {
    func summarize(_ text: String) -> JSValue?
}

// MARK: - Plugin Context Implementation

@objc class PluginContext: NSObject {
    let notes = NotesAPI()
    let mail = MailAPI()
    let tasks = TasksAPI()
    let calendar = CalendarAPI()
    let files = FilesAPI()
    let ai = AIAPI()
}

@objc class NotesAPI: NSObject, NotesJSExport {
    func create(_ content: String) -> String {
        print("[Plugin Sandbox] Notes.create called with: \(content)")
        let note = NotesBackend().createNote()
        var updated = note
        updated.content = content
        NotesBackend().updateNote(updated)
        return note.id.uuidString
    }
    func update(_ id: String, _ content: String) {
        print("[Plugin Sandbox] Notes.update called for \(id)")
        if let uuid = UUID(uuidString: id),
           let note = NotesBackend().notes.first(where: { $0.id == uuid }) {
            var updated = note
            updated.content = content
            NotesBackend().updateNote(updated)
        }
    }
    func delete(_ id: String) {
        print("[Plugin Sandbox] Notes.delete called for \(id)")
        if let uuid = UUID(uuidString: id),
           let note = NotesBackend().notes.first(where: { $0.id == uuid }) {
            NotesBackend().deleteNote(note)
        }
    }
}

@objc class MailAPI: NSObject, MailJSExport {
    func send(_ to: String, _ subject: String, _ body: String) {
        print("[Plugin Sandbox] Mail.send called to \(to)")
    }
}

@objc class TasksAPI: NSObject, TasksJSExport {
    func create(_ title: String) -> String {
        print("[Plugin Sandbox] Tasks.create called: \(title)")
        let task = WorkspaceTask(title: title)
        TasksManager.shared.addTask(task)
        return task.id.uuidString
    }
    func complete(_ id: String) {
        print("[Plugin Sandbox] Tasks.complete called for \(id)")
        if let uuid = UUID(uuidString: id),
           let task = TasksManager.shared.tasks.first(where: { $0.id == uuid }) {
            TasksManager.shared.toggleComplete(task)
        }
    }
}

@objc class CalendarAPI: NSObject, CalendarJSExport {
    func createEvent(_ title: String, _ dateISO: String) -> String {
        print("[Plugin Sandbox] Calendar.createEvent called: \(title) at \(dateISO)")
        // In a real app, parse dateISO and call CalendarManager.shared.addEvent(...)
        return UUID().uuidString
    }
}

@objc class FilesAPI: NSObject, FilesJSExport {
    func listFiles() -> [String] {
        print("[Plugin Sandbox] Files.listFiles called")
        return ["document.pdf", "image.png", "notes.txt"]
    }
    func readFile(_ path: String) -> String {
        print("[Plugin Sandbox] Files.readFile called: \(path)")
        return "Content of \(path)"
    }
}

@objc class AIAPI: NSObject, AIJSExport {
    func summarize(_ text: String) -> JSValue? {
        print("[Plugin Sandbox] AI.summarize called")
        let summary = "Summary: \(text.prefix(50))..."
        return JSValue(object: summary, in: JSContext.current())
    }
}

// MARK: - Sandbox Engine

final class PluginSandbox {
    private let context: JSContext
    private let plugin: Plugin

    init(plugin: Plugin) {
        self.plugin = plugin
        self.context = JSContext() ?? JSContext()

        setupSandbox()
    }

    private func setupSandbox() {
        context.exceptionHandler = { context, exception in
            let error = exception?.toString() ?? "Unknown JS Error"
            print("[Plugin Sandbox] [\(self.plugin.identifier)] Error: \(error)")
        }

        let sdk = PluginContext()
        context.setObject(sdk, forKeyedSubscript: "ctx" as NSString)

        context.evaluateScript(plugin.sourceCode)
    }

    func execute(event: PluginEvent) -> String {
        guard let onEvent = context.objectForKeyedSubscript("onEvent") else {
            return "Error: 'onEvent' function not found in plugin source."
        }

        if onEvent.isUndefined || onEvent.isNull {
            return "Error: 'onEvent' is not a function."
        }

        let jsEvent: [String: Any] = [
            "type": event.type.rawValue,
            "capability": event.capability.rawValue,
            "payload": event.payload,
            "timestamp": event.timestamp.timeIntervalSince1970
        ]

        let result = onEvent.call(withArguments: [jsEvent, context.objectForKeyedSubscript("ctx") as Any])

        return result?.toString() ?? "Success"
    }
}
