import SwiftUI
struct MeetingNotesView: View {
    @StateObject private var backend = MeetingNotesBackend()
    var body: some View { VStack { Text(backend.notes); Button("Generate") { backend.generate() } }.navigationTitle("Meeting Notes") }
}
struct MeetingNotesTool: Tool {
    let name = "Meeting Notes"
    let icon = "calendar.badge.clock"
    let category = ToolCategory.ai
    let complexity = ToolComplexity.advanced
    let description = "Generate meeting notes"
    let isOfflineCapable = false
    let requiresAPI = true
    let isAIEnabled = true
    let complexityLevel = 4
    var view: AnyView { AnyView(MeetingNotesView()) }
}
