import SwiftUI
import Foundation

struct SpaceAuditEvent: Identifiable {
    let id = UUID()
    let message: String
    let timestamp: Date
}

final class WorkspaceCommandCenterService: ObservableObject {
    @Published private(set) var auditEvents: [SpaceAuditEvent] = []

    func runAudit() {
        auditEvents.insert(SpaceAuditEvent(message: "Audit scanned \(CollaborationManager.shared.spaces.count) spaces", timestamp: Date()), at: 0)
    }
}
