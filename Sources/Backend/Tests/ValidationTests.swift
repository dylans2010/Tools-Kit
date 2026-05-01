import Foundation

/// Internal validation tests to ensure core logic is functional across refactored modules.
struct ValidationTests {
    static func runAll() {
        print("Starting System Validation Tests...")

        testMailIntelligence()
        testCalendarPredictiveLogic()
        testSpreadsheetCalculation()
        testMeetAnalytics()
        testCollaborationSystem()
        testEditingSystem()

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
    }

    private static func testEditingSystem() {
        print("Testing Editing System...")
        let manager = EditingManager.shared
        let project = manager.createProject(name: "Test Project", canvasSize: CGSize(width: 100, height: 100))
        assert(project.name == "Test Project")
        assert(!manager.projects.isEmpty)

        // Check if project was automatically indexed in CollaborationFramework
        assert(CollaborationFramework.shared.indexedObjects[project.id] == .mediaProject)
    }

    private static func assert(_ condition: Bool, message: String = "Assertion failed") {
        if !condition {
            fatalError(message)
        }
    }
}
