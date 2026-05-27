import Foundation
import SwiftUI

enum SpeechAIAction: String, CaseIterable, Identifiable {
    case summarize = "Summarize"
    case keyPoints = "Key Points"
    case actionItems = "Action Items"
    case clarify = "Clarify"
    case expand = "Expand"

    var id: String { self.rawValue }

    var icon: String {
        switch self {
        case .summarize: return "text.alignleft"
        case .keyPoints: return "list.bullet.indent"
        case .actionItems: return "checkmark.circle"
        case .clarify: return "questionmark.circle"
        case .expand: return "arrow.up.right.and.arrow.down.left.rectangle"
        }
    }
}
