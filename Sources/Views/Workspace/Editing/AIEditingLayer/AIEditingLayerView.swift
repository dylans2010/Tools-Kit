import SwiftUI

struct AIEditingLayerView: View {
    let projectID: UUID

    var body: some View {
        List(AIEditingPreset.allCases) { preset in
            Button(preset.rawValue) {
                AIEditingService.shared.run(preset: preset, projectID: projectID)
            }
        }
        .navigationTitle("AI Editing")
    }
}
