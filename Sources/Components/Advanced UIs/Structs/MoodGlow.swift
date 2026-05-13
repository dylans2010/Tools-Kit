import Aurora
import SwiftUI

public struct MoodGlow: View {
    public var mood: AuroraGlow.Mood
    public var style: AuroraGlow.Style

    public init(mood: AuroraGlow.Mood = .neutral, style: AuroraGlow.Style = .standard) {
        self.mood = mood
        self.style = style
    }

    public var body: some View {
        AuroraGlow(style)
            .mood(mood)
            .ignoresSafeArea()
    }
}
