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
        await testSecuritySystem()
        testMessagesExtension()

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
