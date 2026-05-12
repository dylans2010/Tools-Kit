import Foundation
import SwiftUI

struct KeyboardState: Sendable {
    var currentText: String = ""
    var suggestions: [Suggestion] = []
    var toneMode: RewriteStyle = .standard
    var accessMode: AccessMode = .local
    var lastSnapshot: String = ""
    var isLoading: Bool = false
    var analysis: TextAnalysis? = nil
    var bestRewrite: String? = nil
}

enum AccessMode: String, Codable, Sendable {
    case local = "Local Mode"
    case ai = "AI Mode"
}
