import SwiftUI
struct MeetingNotesView: View {
    @StateObject private var backend = MeetingNotesBackend()
    var body: some View {
        VStack(spacing: 20) {
            Text(backend.notes)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)

            Button("Generate Meeting Notes") {
                backend.generate()
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding()
        .navigationTitle("Meeting Notes")
    }
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
