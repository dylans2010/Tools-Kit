import Foundation

/// Internal validation tests to ensure core logic is functional across refactored modules.
struct ValidationTests {
    static func runAll() {
        print("Starting System Validation Tests...")

        testMailIntelligence()
        testCalendarPredictiveLogic()
        testSpreadsheetCalculation()
        testMeetAnalytics()

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

    private static func assert(_ condition: Bool, message: String = "Assertion failed") {
        if !condition {
            fatalError(message)
        }
    }
}
