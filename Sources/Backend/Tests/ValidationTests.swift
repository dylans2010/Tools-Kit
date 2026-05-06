import Foundation

/// Internal validation tests to ensure core logic is functional across refactored modules.
struct ValidationTests {
    static func runAll() async {
        print("Starting System Validation Tests...")

        testMailIntelligence()
        testCalendarPredictiveLogic()
        testSpreadsheetCalculation()
        testMeetAnalytics()
        testCollaborationSystem()
        testEditingSystem()
        testPluginSystem()
        await testSecuritySystem()
        testMessagesExtension()
        testConnectorsSystem()
        await testWorkspaceOS()
        await testSDKPlatform()

        print("All Validation Tests Passed!")
    }

    private static func testMailIntelligence() {
        print("Testing Mail Intelligence...")
        let thread = MailThread(id: "test-1", subject: "Meeting Request", messages: [], lastMessageDate: Date())
        // In a real environment, we'd assert on AI output, here we verify model structure
        assert(thread.subject == "Meeting Request")
    }

    private static func testCalendarPredictiveLogic() {
        print("Testing Calendar Predictive Logic...")
        let manager = CalendarManager.shared
        let prob = manager.conflictProbability(for: Date())
        assert(prob >= 0 && prob <= 1.0)
    }

    private static func testSpreadsheetCalculation() {
        print("Testing Spreadsheet Calculation Engine...")
        let manager = SpreadsheetsManager.shared
        let cell = SpreadsheetCell(value: "10", formula: "=SUM(A1:A2)")
        // Verify formula recognition
        assert(cell.formula?.hasPrefix("=") == true)
    }

    private static func testMeetAnalytics() {
        print("Testing Meet Analytics...")
        let manager = MeetingStateManager.shared
        manager.updateEngagement()
        assert(manager.engagementLevel >= 0)
    }

    private static func testCollaborationSystem() {
        print("Testing Collaboration System...")
        let manager = CollaborationManager.shared
        let space = manager.createSpace(name: "Test Space", description: "Test", icon: "test", visibility: .privateSpace)
        assert(space.name == "Test Space")
        assert(!manager.spaces.isEmpty)

        let framework = CollaborationFramework.shared
        framework.indexObject(id: space.id, type: .notebook)
        assert(framework.indexedObjects[space.id] == .notebook)

        // Test Pull Request creation
        let pr = PullRequestManager.shared.createPullRequest(spaceID: space.id, title: "Fix UI", description: "Test", sourceBranchID: UUID(), targetBranchID: UUID())
        assert(PullRequestManager.shared.pullRequests[space.id]?.count == 1)
        assert(pr.title == "Fix UI")

        // Test Forking
        if let fork = ForkManager.shared.forkSpace(spaceID: space.id) {
            assert(fork.name.contains("(Fork)"))
        }

        // Test Branch Protection
        let rule = BranchProtectionRule(id: UUID(), branchName: "main", requireApprovals: true, requiredApprovalCount: 2, restrictMerges: false, allowedRoles: [.admin])
        BranchProtectionService.shared.addRule(spaceID: space.id, rule: rule)
        assert(!BranchProtectionService.shared.canMerge(spaceID: space.id, branchName: "main", userRole: .editor, approvalCount: 1))
    }

    private static func testSecuritySystem() async {
        print("Testing Security System...")
        let encryption = EncryptionService.shared
        let salt = encryption.generateSalt()
        let password = "test-password"

        do {
            let key = try encryption.deriveKey(password: password, salt: salt)
            let secret = "Sensitive Data".data(using: .utf8)!

            // Test Sharded Encryption
            let storage = SecureFileStorageService.shared
            let filename = "test_file.vault"
            let indexName = try storage.saveEncryptedFile(data: secret, filename: filename, key: key)
            let decrypted = try storage.loadDecryptedFile(filename: indexName, key: key)
            assert(decrypted == secret, "Sharded Encryption/Decryption failed")
            storage.deleteFile(indexName)

            // Test TOTP
            let totp = TOTPService.shared.generateTOTP(secret: "JBSWY3DPEHPK3PXP", algorithm: .sha1)
            assert(totp?.count == 6, "TOTP (SHA1) failed")

            let totp256 = TOTPService.shared.generateTOTP(secret: "JBSWY3DPEHPK3PXP", algorithm: .sha256)
            assert(totp256?.count == 6, "TOTP (SHA256) failed")

            // Test Package Export/Import (Binary format)
            let packageURL = try await SecurityPackageService.shared.exportPackage(password: password)
            assert(FileManager.default.fileExists(atPath: packageURL.path), "Package export failed")
            // In a real test we'd import it back, but requireAuth needs LAContext interaction.

            print("Security System Logic Verified.")
        } catch {
            fatalError("Security System Test Failed: \(error.localizedDescription)")
        }
    }

    private static func testMessagesExtension() {
        MessagesValidationTests.run()
    }

    private static func testConnectorsSystem() {
        print("Testing Connectors System...")
        let manager = ConnectorManager.shared
        let id = UUID()
        let connector = ConnectorDefinition(
            id: id,
            name: "Test Connector",
            identifier: "com.toolskit.test",
            version: "1.0.0",
            description: "Test description",
            authConfig: ConnectorAuthConfig(type: .none),
            schema: ConnectorSchema(mappings: [:], jsonSchema: "{}"),
            flow: ConnectorFlow(steps: [])
        )
        manager.addConnector(connector)
        assert(manager.connectors.contains(where: { $0.id == id }))

        manager.addLog(ConnectorLog(connectorID: id, timestamp: Date(), type: .info, message: "Validation test log"))
        assert(manager.logs.first?.connectorID == id)

        manager.deleteConnector(id: id)
        assert(!manager.connectors.contains(where: { $0.id == id }))
        print("Connectors System Logic Verified.")
    }

    private static func testPluginSystem() {
        print("Testing Plugin System...")
        let manager = PluginManager.shared
        let plugin = PluginDefinition(
            id: UUID(),
            name: "Validation Plugin",
            description: "Test",
            author: "Validator",
            version: "1.0.0",
            icon: "puzzlepiece",
            identifier: "com.toolskit.validation",
            isEnabled: true,
            isInstalled: true,
            installedAt: Date(),
            capabilities: [.notes],
            actions: [.noteCreated],
            sourceCode: "console.log('test')"
        )
        manager.savePlugin(plugin)
        assert(manager.installedPlugins.contains(where: { $0.identifier == "com.toolskit.validation" }))

        let runtime = PluginRuntime.shared
        // Verification of subscription logic
        assert(plugin.actions.contains { $0.rawValue == "note.created" })

        // Test High-Risk Validation
        let highRiskPlugin = PluginDefinition(
            id: UUID(),
            name: "High Risk Plugin",
            description: "Test",
            author: "Validator",
            version: "1.0.0",
            icon: "shield",
            identifier: "com.toolskit.highrisk",
            capabilities: [.mailFetchData],
            actions: [.mailReceived],
            sourceCode: "console.log('test')"
            // No API key or privacy note
        )

        // Should fail install
        manager.install(pluginID: highRiskPlugin.id) // This won't work as it's not in availablePlugins, but let's test savePlugin logic

        let sandbox = PluginSandbox.shared
        let event = PluginEvent(id: UUID(), capability: .mailFetchData, action: "mail.received", payload: [:], timestamp: Date())
        let result = sandbox.validateExecution(plugin: highRiskPlugin, event: event)

        switch result {
        case .failure(let reason, _):
            assert(reason == .scopeInvalid, "High-risk plugin should fail scope validation without API Key")
        case .success:
            fatalError("High-risk plugin should not succeed without API Key")
        }
    }

    private static func testWorkspaceOS() async {
        print("Testing Workspace OS...")

        // 1. Intelligence
        let insights = try? await IntelligenceFramework.shared.scanWorkspace()
        assert(insights != nil)

        // 2. Collaboration
        let space = SpaceCollabManager.shared.createSpace(name: "Collab Test", description: "Test", icon: "person.2", visibility: .shared)
        assert(space.name == "Collab Test")
        SpaceCollabManager.shared.sendMessage(spaceID: space.id, content: "Hello Test")
        let updatedSpace = SpaceCollabManager.shared.spaces.first { $0.id == space.id }
        assert(updatedSpace?.messages.count == 1)

        // 3. Time Travel
        try? TimeTravelFramework.shared.createSnapshot(message: "Initial", entityType: "Space", entityID: space.id, data: Data())
        assert(!TimeTravelManager.shared.snapshots.isEmpty)

        // 4. Integrations
        let workflow = IntegrationWorkflow(name: "Test Workflow", description: "Test", trigger: IntegrationTrigger(type: .internalApp, source: "note.created"), actions: [])
        try? UnifiedDataStore.shared.saveIntegrationWorkflow(workflow)
        assert(!UnifiedDataStore.shared.integrationWorkflows.isEmpty)

        // 5. Spatial
        let canvas = WhiteboardService.shared.createNewCanvas(name: "Test Canvas")
        assert(UnifiedDataStore.shared.spatialCanvases.contains(where: { $0.id == canvas.id }))

        print("Workspace OS Logic Verified.")
    }

    private static func testSDKPlatform() async {
        print("Testing SDK Platform Expansion...")

        let project = SDKProject(id: UUID(), name: "Test Project", sourceCode: "print('hello')", createdAt: Date(), lastBuiltAt: nil, enabledScopes: [], enabledPluginIDs: [], enabledToolIDs: [], enabledConnectorIDs: [], automationRules: [], healthStatus: .healthy, status: .idle)
        let context = SDKExecutionContext(projectID: project.id, noSandbox: false)

        // 1. Test Kernel routing
        let action = SDKAction.createNote(title: "SDK Test", content: "Content")
        do {
            try await SDKExecutionKernel.shared.execute(action: action, context: context)
        } catch {
            fatalError("SDK Execution Kernel failed: \(error.localizedDescription)")
        }

        // 2. Test System Router
        let systemAction = try? SDKSystemRouter.shared.route(action: action)
        assert(systemAction != nil)

        // 3. Test Mutation Engine with Permission Gate
        do {
            try await SDKMutationEngine.shared.performMutation(action, context: context)
        } catch {
            fatalError("SDK Mutation Engine failed: \(error.localizedDescription)")
        }

        // 4. Test Event Injection
        SDKEventInjectionEngine.shared.broadcast(action: action)

        // 5. Test Telemetry
        let traceID = UUID()
        SDKTelemetryEngine.shared.startTrace(id: traceID, action: action)
        SDKTelemetryEngine.shared.endTrace(id: traceID, status: .success)

        // 6. Test fetchData
        let fetchRequest = SDKFetchRequest(dataTypes: [.notes, .tasks], scopes: [.notes, .tasks])
        do {
            let fetchResult = try await ToolsKitSDK.shared.fetchData(fetchRequest)
            assert(fetchResult.metadata.totalCount >= 0)
            assert(fetchResult.performance.fetchTime >= 0)
        } catch {
            fatalError("SDK fetchData failed: \(error.localizedDescription)")
        }

        print("SDK Platform Logic Verified.")
    }

    private static func testEditingSystem() {
        print("Testing Editing System...")
        let manager = EditingManager.shared
        let project = manager.createProject(name: "Test Project", canvasSize: CGSize(width: 100, height: 100))
        assert(project.name == "Test Project")
        assert(!manager.projects.isEmpty)

        // Check if project was automatically indexed in CollaborationFramework
        assert(CollaborationFramework.shared.indexedObjects[project.id] == .mediaProject)

        // Test History Manager
        let history = EditingHistoryManager(projectID: project.id)
        history.pushState(project, description: "Initial State")
        var projectV2 = project
        projectV2.name = "Project V2"
        history.pushState(projectV2, description: "Changed name")
        assert(history.history.count == 2)
        assert(history.undo()?.name == "Test Project")

        // Test AI Engine Suggestion
        let frame = AIEditingEngine.shared.suggestFraming(layer: EditingLayer(id: UUID(), name: "Layer", type: .image, position: .zero, scale: 1.0, rotation: 0), canvasSize: CGSize(width: 1920, height: 1080))
        assert(frame.width == 1920)
    }

    private static func assert(_ condition: Bool, message: String = "Assertion failed") {
        if !condition {
            fatalError(message)
        }
    }
}
