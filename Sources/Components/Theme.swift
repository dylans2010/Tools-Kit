import SwiftUI

extension Color {
    static let workspaceBackground = Color.workspaceBackground ?? .black
    static let workspaceSurface = Color.workspaceSurface
    static let workspaceAccent = Color.blue
    static let workspaceSecondary = Color.secondary
    static let workspacePrimary = Color.white
    static let workspaceError = Color.red
    static let workspaceSuccess = Color.green
    static let workspaceWarning = Color.orange

    static let aiGradientStart = Color.purple
    static let aiGradientEnd = Color.blue
}

struct WorkspaceTheme {
    static let cornerRadius: CGFloat = 16
    static let spacing: CGFloat = 16
    static let horizontalPadding: CGFloat = 20
}
