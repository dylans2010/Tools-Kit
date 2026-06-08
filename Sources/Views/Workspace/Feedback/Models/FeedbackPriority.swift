import SwiftUI

public enum FeedbackPriority: Int, CaseIterable, Identifiable, Codable, Comparable {
    case low = 1, medium = 2, high = 3, critical = 4

    public var id: Int { rawValue }

    public var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }

    public var color: Color {
        switch self {
        case .low: return .blue
        case .medium: return .green
        case .high: return .orange
        case .critical: return .red
        }
    }

    public static func < (lhs: FeedbackPriority, rhs: FeedbackPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
