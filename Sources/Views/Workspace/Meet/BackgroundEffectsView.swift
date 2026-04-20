import SwiftUI

struct BackgroundEffectsView: View {
    let selectedEffect: MeetingBackgroundEffect
    let onSelectEffect: (MeetingBackgroundEffect) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Background Effects", systemImage: "sparkles.rectangle.stack")
                .font(.subheadline.weight(.semibold))
            Picker("Background", selection: Binding(get: { selectedEffect }, set: onSelectEffect)) {
                ForEach(MeetingBackgroundEffect.allCases) { effect in
                    Text(effect.displayName).tag(effect)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}
