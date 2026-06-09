import SwiftUI

public struct FeedbackDraftsView: View {
    let drafts: [FeedbackReport]
    @Environment(\.dismiss) private var dismiss

    public init(drafts: [FeedbackReport]) {
        self.drafts = drafts
    }

    public var body: some View {
        List {
            if drafts.isEmpty {
                Text("No drafts saved.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(drafts) { draft in
                    NavigationLink(destination: ReporterFeedbackView(category: draft.category)) {
                        VStack(alignment: .leading) {
                            Text(draft.summary.isEmpty ? "Untitled Draft" : draft.summary)
                                .font(.headline)
                            Text("Last saved: \(draft.updatedAt.formatted())")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Drafts")
    }
}
