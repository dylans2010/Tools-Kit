import SwiftUI

extension Color {
    static let workspaceBackground = Color(.systemBackground)
    static let workspaceSurface = Color(.secondarySystemBackground)
    static let workspaceAccent = Color.blue
    static let workspaceSecondary = Color.secondary
    static let workspacePrimary = Color.primary
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

/// A standardized surface card for workspace modules with consistent styling.
struct WorkspaceSurfaceCard<Content: View>: View {
    let content: Content
    let padding: CGFloat

    init(padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.workspaceSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
}
