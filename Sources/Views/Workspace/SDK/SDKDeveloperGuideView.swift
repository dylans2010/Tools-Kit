import SwiftUI

/// Developer Guide — full in-app documentation for WorkspaceSDK.
/// Provides architecture explanation, module breakdown, and real Swift code examples.
struct SDKDeveloperGuideView: View {
    @State private var selectedSection: GuideSection = .gettingStarted
    @State private var guideMode: GuideMode = .basic

    enum GuideMode: String, CaseIterable, Identifiable {
        case basic = "Basic"
        case advanced = "Advanced"

        var id: String { rawValue }
    }

    enum GuideSection: String, CaseIterable, Identifiable {
        case gettingStarted = "Getting Started"
        case architecture = "Architecture"
        case mail = "Mail Module"
        case notebooks = "Notebooks Module"
        case meet = "Meet Module"
        case articles = "Articles Module"
        case events = "Event System"
        case plugins = "Building Plugins"
        case dataLayer = "Data Layer"
        case apiRouter = "API Router"
        case security = "Security"

        var id: String { rawValue }
        var icon: String {
            switch self {
            case .gettingStarted: return "play.circle.fill"
            case .architecture: return "building.columns.fill"
            case .mail: return "envelope.fill"
            case .notebooks: return "book.fill"
            case .meet: return "video.fill"
            case .articles: return "doc.text.fill"
            case .events: return "bolt.fill"
            case .plugins: return "puzzlepiece.extension.fill"
            case .dataLayer: return "cylinder.split.1x2.fill"
            case .apiRouter: return "network"
            case .security: return "lock.shield.fill"
            }
        }
    }

    var body: some View {
        List {
            Section {
                Picker("Guide Mode", selection: $guideMode) {
                    ForEach(GuideMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Text(guideMode == .basic ? "Simple walkthroughs with tiny code snippets and plain-English explanations." : "Deep architecture notes, production patterns, and full developer examples.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Guide Mode")
            }

            Section {
                ForEach(GuideSection.allCases) { section in
                    Button {
                        selectedSection = section
                    } label: {
                        HStack {
                            Image(systemName: section.icon)
                                .foregroundStyle(.blue)
                                .frame(width: 24)
                            Text(section.rawValue)
                            Spacer()
                            if selectedSection == section {
                                Image(systemName: "checkmark").foregroundStyle(.blue)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Documentation")
            }

            Section(selectedSection.rawValue) {
                guideContent(for: selectedSection)
            }
        }
        .navigationTitle("Developer Guide")
    }

    // MARK: - Content Router

    @ViewBuilder
    private func guideContent(for section: GuideSection) -> some View {
        if guideMode == .basic {
            basicGuideContent(for: section)
        } else {
            advancedGuideContent(for: section)
        }
    }

    @ViewBuilder
    private func advancedGuideContent(for section: GuideSection) -> some View {
        switch section {
        case .gettingStarted: gettingStartedContent
        case .architecture: architectureContent
        case .mail: mailContent
        case .notebooks: notebooksContent
        case .meet: meetContent
        case .articles: articlesContent
        case .events: eventsContent
        case .plugins: pluginsContent
        case .dataLayer: dataLayerContent
        case .apiRouter: apiRouterContent
        case .security: securityContent
        }
    }

    @ViewBuilder
    private func basicGuideContent(for section: GuideSection) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            docText(basicIntro(for: section))
            codeBlock(basicSnippet(for: section))
            docSection("How it works", content: basicExplanation(for: section))
        }
    }

    private func basicIntro(for section: GuideSection) -> String {
        switch section {
        case .gettingStarted: return "Start here. Create one SDK instance, initialize it, then call the modules you need."
        case .architecture: return "Think of the SDK as layers: app UI at the top, services in the middle, storage and security at the bottom."
        case .mail: return "Use the mail module when your feature needs to read, organize, or send messages."
        case .notebooks: return "Use notebooks to create pages, save edits, and search user notes."
        case .meet: return "Use meet to create sessions, add people, and keep meeting notes together."
        case .articles: return "Use articles for long-form content, publishing, tags, and search."
        case .events: return "Events let one part of your app announce something and another part react to it."
        case .plugins: return "Plugins are small apps that run inside Workspace with permissions and lifecycle hooks."
        case .dataLayer: return "The data layer saves user records locally so features can work offline."
        case .apiRouter: return "The router gives your app simple named endpoints for SDK actions."
        case .security: return "Security scopes decide what each app or plugin is allowed to do."
        }
    }

    private func basicSnippet(for section: GuideSection) -> String {
        switch section {
        case .gettingStarted: return """
let sdk = WorkspaceSDK.shared
await sdk.initialize()
print(sdk.version)
"""
        case .architecture: return """
// UI asks a service to do work.
let notes = sdk.notebooks.listNotebooks()
"""
        case .mail: return """
let inbox = sdk.mail.listMessages()
print(inbox.count)
"""
        case .notebooks: return """
let page = try sdk.notebooks.createPage(
    title: "Ideas"
)
"""
        case .meet: return """
let session = try sdk.meet.createSession(
    title: "Planning"
)
"""
        case .articles: return """
let article = try sdk.articles.createArticle(
    title: "Launch Notes"
)
"""
        case .events: return """
sdk.emit(channel: "app", name: "saved")
"""
        case .plugins: return """
try await sdk.plugins.start(appId: plugin.id)
"""
        case .dataLayer: return """
try sdk.save(myRecord)
let records = sdk.fetchAll(MyRecord.self)
"""
        case .apiRouter: return """
let response = try await sdk.api("/sdk/health")
"""
        case .security: return """
let ok = sdk.security.checkPermission(
    for: appId, scope: "read"
)
"""
        }
    }

    private func basicExplanation(for section: GuideSection) -> String {
        switch section {
        case .gettingStarted: return "Initialize once at launch. After that, every SDK service is available from the shared SDK object."
        case .architecture: return "Views stay simple. Services own business logic. Storage persists user data. Security checks permissions before sensitive work runs."
        case .mail: return "The mail service talks to configured accounts, returns user messages, and emits events when messages change."
        case .notebooks: return "Notebook calls update local data first, then notify the rest of the app so lists and search refresh."
        case .meet: return "Meeting sessions group participants, notes, and lifecycle state so your UI can show what is active."
        case .articles: return "Article records keep content, metadata, and publishing state together for editing and discovery."
        case .events: return "Publish an event when something happens. Subscribers receive it without tight coupling."
        case .plugins: return "A plugin registers its metadata, requests permissions, then starts and stops through the runtime."
        case .dataLayer: return "Models are encoded to local storage by type, so user content survives relaunches and works offline."
        case .apiRouter: return "Routes wrap SDK actions behind predictable paths so automation and plugins can call them consistently."
        case .security: return "Before a plugin reads, writes, or connects externally, the SDK checks whether its scopes allow that action."
        }
    }

    // MARK: - Getting Started

    private var gettingStartedContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            docText("WorkspaceSDK is a full on-device developer platform. Initialize it once at app launch:")

            codeBlock("""
            // Initialize the SDK
            let sdk = WorkspaceSDK.shared
            await sdk.initialize()
            
            // Check if ready
            if sdk.isInitialized {
                print("SDK v\\(sdk.version) is ready")
            }
            
            // Access any module
            let messages = sdk.mail.listMessages()
            let notebooks = sdk.notebooks.listNotebooks()
            let sessions = sdk.meet.listSessions()
            """)

            docText("The SDK handles all computation, storage, and orchestration. Views only consume data from SDK services — never contain business logic.")

            docText("All data is persisted offline-first using the unified SDKDataStore. No network required for local operations.")
        }
    }

    // MARK: - Architecture

    private var architectureContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            docText("WorkspaceSDK follows a layered architecture:")

            docSection("Kernel Layer", content: "WorkspaceSDKKernel bootstraps the SDK, initializes all services, manages lifecycle. SDKContext carries request-scoped metadata. SDKEnvironment manages configuration and feature flags.")

            docSection("Dependency Injection", content: "ServiceRegistry provides protocol-based resolution with lazy initialization. ServiceContainer registers all defaults. Use @ServiceInjected property wrapper for injection.")

            codeBlock("""
            // Using dependency injection
            struct MyService {
                @ServiceInjected var dataStore: SDKDataStoreProtocol
                @ServiceInjected var eventBus: SDKEventBusProtocol
                
                func doWork() {
                    let items = dataStore.fetchAll(SDKArticle.self)
                    eventBus.publish(SDKBusEvent(
                        channel: "custom",
                        name: "work.done",
                        data: ["count": "\\(items.count)"]
                    ))
                }
            }
            """)

            docSection("Data Layer", content: "SDKDataStore provides offline-first JSON persistence with indexing and querying. All models conform to SDKModel protocol.")

            docSection("Router", content: "SDKRouter handles on-device API routing with structured request/response. Register custom endpoints for your modules.")

            docSection("Event Bus", content: "SDKEventBus provides publish/subscribe across all modules with persistent history.")

            docSection("Plugin Runtime", content: "PluginRuntimeEngine manages app lifecycle with sandboxed execution and permission enforcement.")
        }
    }

    // MARK: - Mail Module

    private var mailContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            docText("SDKMailService handles all email operations — sending, reading, threading, and search.")

            codeBlock("""
            let sdk = WorkspaceSDK.shared
            
            // Send an email
            try await sdk.mail.send(
                to: "user@example.com",
                subject: "Hello from SDK",
                body: "This is sent via WorkspaceSDK"
            )
            
            // List all messages
            let messages = sdk.mail.listMessages()
            
            // Search messages
            let results = sdk.mail.searchMessages(query: "invoice")
            
            // Get thread
            let thread = sdk.mail.getThread(threadId: "thread-id")
            
            // Mark as read
            try sdk.mail.markAsRead(id: messageId)
            
            // Toggle star
            try sdk.mail.toggleStar(id: messageId)
            """)

            docText("Mail events are emitted on the 'mail' channel: mail.sent, mail.deleted")
        }
    }

    // MARK: - Notebooks Module

    private var notebooksContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            docText("SDKNotebookService manages notebooks, pages, and version history.")

            codeBlock("""
            let sdk = WorkspaceSDK.shared
            
            // Create a notebook
            let notebook = try sdk.notebooks.createNotebook(
                title: "My Research"
            )
            
            // Add pages
            let page = try sdk.notebooks.addPage(
                to: notebook.id,
                title: "Chapter 1",
                content: "Initial content here..."
            )
            
            // Update page (auto-versions)
            try sdk.notebooks.updatePage(
                in: notebook.id,
                pageId: page.id,
                content: "Updated content — previous version saved"
            )
            
            // View version history
            let history = sdk.notebooks.getPageHistory(
                notebookId: notebook.id,
                pageId: page.id
            )
            for version in history {
                print("v\\(version.versionNumber): \\(version.savedAt)")
            }
            
            // Search across notebooks
            let results = sdk.notebooks.searchNotebooks(
                query: "research"
            )
            """)

            docText("Notebook events: notebook.created, notebook.updated, notebook.deleted, page.created, page.updated")
        }
    }

    // MARK: - Meet Module

    private var meetContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            docText("SDKMeetService manages meeting sessions, presence, and collaboration.")

            codeBlock("""
            let sdk = WorkspaceSDK.shared
            
            // Create a session
            let session = try sdk.meet.createSession(
                title: "Team Standup",
                participants: ["alice", "bob"]
            )
            
            // Start the session (connects to Daily.co)
            try await sdk.meet.startSession(id: session.id)
            
            // Manage participants
            try sdk.meet.addParticipant(
                sessionId: session.id,
                participant: "charlie"
            )
            
            // Add meeting notes
            try sdk.meet.addNotes(
                sessionId: session.id,
                notes: "Discussed Q3 roadmap"
            )
            
            // End session
            try sdk.meet.endSession(id: session.id)
            
            // Query active sessions
            let active = sdk.meet.activeSessions()
            """)

            docText("Meet events: session.created, session.started, session.ended, participant.joined, participant.left")
        }
    }

    // MARK: - Articles Module

    private var articlesContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            docText("SDKArticleService handles article creation, publishing, and content management.")

            codeBlock("""
            let sdk = WorkspaceSDK.shared
            
            // Create an article
            let article = try sdk.articles.createArticle(
                title: "Getting Started with SwiftUI",
                content: "SwiftUI is a framework...",
                author: "Developer",
                tags: ["swift", "ios", "tutorial"]
            )
            
            // Publish
            try sdk.articles.publish(id: article.id)
            
            // Search
            let results = sdk.articles.searchArticles(
                query: "SwiftUI"
            )
            
            // Parse raw content
            let parsed = sdk.articles.parseContent(rawMarkdown)
            print("Read time: \\(parsed.estimatedReadTime) min")
            """)

            docText("Article events: article.created, article.updated, article.published, article.deleted")
        }
    }

    // MARK: - Events

    private var eventsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            docText("SDKEventBus provides real-time publish/subscribe communication across all SDK modules.")

            codeBlock("""
            let sdk = WorkspaceSDK.shared
            
            // Subscribe to a channel
            let subscription = sdk.on(channel: "mail") { event in
                print("Event: \\(event.name)")
                print("Data: \\(event.data)")
            }
            
            // Publish a custom event
            sdk.emit(
                channel: "custom",
                name: "user.action",
                data: ["action": "button_tap"]
            )
            
            // Subscribe to all events
            let allSub = sdk.events.subscribeAll { event in
                print("[\\(event.channel)] \\(event.name)")
            }
            
            // Query event history
            let recent = sdk.events.recentEvents(limit: 20)
            let mailEvents = sdk.events.events(
                forChannel: "mail"
            )
            """)

            docText("Built-in channels: sdk.lifecycle, mail, notebooks, meet, articles, sdk.apps. Create custom channels for your own modules.")
        }
    }

    // MARK: - Plugins

    private var pluginsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            docText("Build and register apps that run on top of WorkspaceSDK with full lifecycle management.")

            codeBlock("""
            // Define your app
            let myApp = SDKAppDefinition(
                name: "Analytics Dashboard",
                version: "1.0.0",
                author: "My Team",
                description: "Real-time workspace analytics",
                permissions: ["read", "events"]
            )
            
            // Register with the runtime
            try WorkspaceSDK.shared.plugins.register(myApp)
            
            // Start the app
            try await WorkspaceSDK.shared.plugins.start(
                appId: myApp.id
            )
            
            // Check if running
            let isRunning = WorkspaceSDK.shared.plugins.isRunning(
                myApp.id
            )
            
            // Stop the app
            try await WorkspaceSDK.shared.plugins.stop(
                appId: myApp.id
            )
            
            // Implement lifecycle hooks
            class MyAppLifecycle: SDKAppLifecycle {
                let appId: UUID
                let appName = "Analytics Dashboard"
                
                init(appId: UUID) { self.appId = appId }
                
                func onInit() async throws {
                    // Setup resources
                }
                func onStart() async throws {
                    // Begin processing
                }
                func onStop() async throws {
                    // Cleanup
                }
            }
            """)

            docText("Apps run in sandboxed environments with permission enforcement. The 'madeForWorkspace' flag enables the 'Made For Workspace' badge in the marketplace.")
        }
    }

    // MARK: - Data Layer

    private var dataLayerContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            docText("SDKDataStore provides offline-first persistence. All models must conform to SDKModel.")

            codeBlock("""
            // Define a custom model
            struct ProjectNote: SDKModel {
                let id: UUID
                var title: String
                var content: String
                let createdAt: Date
                var updatedAt: Date
            }
            
            let sdk = WorkspaceSDK.shared
            
            // Save
            let note = ProjectNote(
                id: UUID(),
                title: "Sprint Notes",
                content: "Week 1 progress...",
                createdAt: Date(),
                updatedAt: Date()
            )
            try sdk.save(note)
            
            // Fetch all
            let allNotes = sdk.fetchAll(ProjectNote.self)
            
            // Query with predicate
            let recent = sdk.query(ProjectNote.self) {
                $0.updatedAt > Calendar.current.date(
                    byAdding: .day, value: -7, to: Date()
                )!
            }
            
            // Delete
            try sdk.storage.delete(ProjectNote.self, id: note.id)
            
            // Collection stats
            let stats = sdk.storage.collectionStats()
            """)

            docText("Data is stored as JSON files in Application Support. Each model type gets its own collection with automatic indexing.")
        }
    }

    // MARK: - API Router

    private var apiRouterContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            docText("SDKRouter provides on-device API routing with structured request/response handling.")

            codeBlock("""
            let sdk = WorkspaceSDK.shared
            
            // Register a custom endpoint
            sdk.router.registerHandler(
                "/myapp/status",
                method: .get
            ) { request in
                SDKResponse(
                    requestId: request.id,
                    status: .success,
                    data: ["status": "operational"]
                )
            }
            
            // Execute an API call
            let response = try await sdk.api(
                "/sdk/health",
                method: .get
            )
            print("Status: \\(response.status)")
            
            // With parameters
            let result = try await sdk.api(
                "/mail/send",
                method: .post,
                parameters: [
                    "to": "user@example.com",
                    "subject": "Test",
                    "body": "Hello"
                ]
            )
            
            // List all routes
            let routes = sdk.apiRoutes()
            for route in routes {
                print("\\(route.method.rawValue) \\(route.path)")
            }
            """)

            docText("Default routes include: /sdk/health, /sdk/info, /sdk/services, /mail/send, /mail/list, /notebooks/create, /notebooks/list, /meet/create, /articles/create, /articles/list")
        }
    }

    // MARK: - Security

    private var securityContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            docText("SDKSecurityPolicy enforces scoped access control and plugin sandboxing.")

            codeBlock("""
            let security = WorkspaceSDK.shared.security
            
            // Check permissions for an app
            let allowed = security.checkPermission(
                for: appId,
                scope: "write"
            )
            
            // Set app-specific permissions
            security.setPermissions(
                for: appId,
                permissions: ["read", "events"]
            )
            
            // Enforce sandbox
            try security.enforceSandbox(
                for: appId,
                action: "network"
            )
            
            // Global deny list
            security.denyScope("admin")
            security.allowScope("admin")
            
            // Audit report
            let report = security.auditReport()
            print("Apps: \\(report.totalAppsWithPermissions)")
            print("Denied: \\(report.deniedScopes)")
            """)

            docText("All plugins run sandboxed by default. Permissions are validated at registration and enforced at runtime. Use SDKPermissionManager for global scope control.")
        }
    }

    // MARK: - Helpers

    private func docText(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.primary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func docSection(_ title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.subheadline).bold()
            Text(content).font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func codeBlock(_ code: String) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Text(code)
                .font(.system(size: 12, design: .monospaced))
                .padding(12)
        }
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}
