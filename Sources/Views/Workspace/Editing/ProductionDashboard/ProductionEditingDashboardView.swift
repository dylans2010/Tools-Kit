import SwiftUI

struct ProductionEditingDashboardView: View {
    let projectID: UUID

    var body: some View {
        List {
            NavigationLink("Non-Destructive Pipeline") { NonDestructivePipelineView(projectID: projectID) }
            NavigationLink("AI Editing Layer") { AIEditingLayerView(projectID: projectID) }
        }
        .navigationTitle("Production Suite")
    }
}
