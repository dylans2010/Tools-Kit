import Foundation

struct PluginValidationTests {
    static func run() {
        print("Testing Plugin System...")

        testPluginModels()
        testPluginEventBus()
        testPluginManager()
        testPluginSandbox()

        print("Plugin System Logic Verified.")
    }

    private static func testPluginModels() {
        print("Testing Plugin Models...")
        let id = UUID()
        let plugin = Plugin(
            id: id,
            identifier: "com.test",
            name: "Test",
            description: "Test",
            icon: "star",
            version: "1.0.0",
            author: "Author",
            capabilities: [.notes],
            actions: [.noteCreated],
            commands: [],
            permissions: [.readNotes],
            sourceCode: "test",
            isEnabled: true,
            isInstalled: true,
            isUserCreated: true,
            createdAt: Date()
        )
        assert(plugin.id == id)
        assert(plugin.identifier == "com.test")
    }

    private static func testPluginEventBus() {
        print("Testing Plugin Event Bus...")
        let bus = PluginEventBus.shared
        var received = false
        let cancellable = bus.events.sink { event in
            if event.type == .noteCreated {
                received = true
            }
        }

        bus.emit(type: .noteCreated, payload: ["test": "val"])

        // In a real test environment we might need to wait, but since it's immediate on main thread dispatch in our mock
        // actually PluginEventBus uses DispatchQueue.main.async, so this might not be immediate.
        // For simple validation, we check the recentEvents buffer which is updated.
        assert(bus.recentEvents.first?.type == .noteCreated)
        cancellable.cancel()
    }

    private static func testPluginManager() {
        print("Testing Plugin Manager...")
        let manager = PluginManager.shared
        let initialCount = manager.installedPlugins.count

        let p = manager.createPlugin(
            name: "New Plugin",
            identifier: "com.test.new",
            description: "Desc",
            icon: "bolt",
            capabilities: [.mail],
            actions: [.mailReceived],
            permissions: [],
            sourceCode: "code"
        )

        assert(manager.installedPlugins.count == initialCount + 1)
        assert(manager.installedPlugins.last?.name == "New Plugin")

        manager.uninstall(pluginID: p.id)
        assert(manager.installedPlugins.count == initialCount)
    }

    private static func testPluginSandbox() {
        print("Testing Plugin Sandbox...")
        let plugin = Plugin(
            id: UUID(),
            identifier: "com.test.sandbox",
            name: "Sandbox Test",
            description: "Test",
            icon: "star",
            version: "1.0.0",
            author: "Author",
            capabilities: [.notes],
            actions: [.noteCreated],
            commands: [],
            permissions: [],
            sourceCode: "export function onEvent(event, ctx) { return 'Received ' + event.type; }",
            isEnabled: true,
            isInstalled: true,
            isUserCreated: true,
            createdAt: Date()
        )

        let sandbox = PluginSandbox(plugin: plugin)
        let event = PluginEvent(type: .noteCreated, payload: [:])
        let result = sandbox.execute(event: event)
        assert(result == "Received note.created")
    }

    private static func assert(_ condition: Bool, message: String = "Assertion failed") {
        if !condition {
            fatalError(message)
        }
    }
}
