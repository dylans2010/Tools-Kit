import SwiftUI

struct PluginGlobalOverlay: ViewModifier {
    func body(content: Content) -> some View {
        content
    }
}

extension View {
    func withPluginOverlay() -> some View {
        self.modifier(PluginGlobalOverlay())
    }
}
