import SwiftUI
struct MeetingNotesView: View {
    @StateObject private var backend = MeetingNotesBackend()
    var body: some View {
        VStack(spacing: 16) {
            if !backend.notes.isEmpty {
                ScrollView {
                    Text(backend.notes)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Text("Tap Generate to create meeting notes")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            Button("Generate Meeting Notes") { backend.generate() }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
