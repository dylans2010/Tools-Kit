import SwiftUI

struct MeetingSummaryView: View {
    let summary: MeetingSummaryState

    var body: some View {
        List {
            Section("AI Recap") {
                Text(summary.recap)
            }

            Section("Action Items") {
                if !summary.actionItems.isEmpty {
                    ForEach(summary.actionItems, id: \.self) { item in
                        Label(item, systemImage: "checkmark.circle")
                    }
                }
            }

            Section("Transcript Preview") {
                Text(summary.transcriptPreview)
                    .foregroundColor(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Meeting Summary")
        .navigationBarTitleDisplayMode(.inline)
    }
}
