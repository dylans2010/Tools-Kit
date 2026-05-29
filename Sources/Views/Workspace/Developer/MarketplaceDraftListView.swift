import SwiftUI

struct MarketplaceDraftListView: View {
    @ObservedObject var marketplaceService = MarketplaceService.shared

    var body: some View {
        List {
            Section("In-Progress Submissions") {
                if marketplaceService.drafts.isEmpty {
                    Text("No active drafts found.").foregroundStyle(.secondary)
                } else {
                    ForEach(marketplaceService.drafts) { draft in
                        NavigationLink(destination: MarketplaceSubmissionView(appID: draft.appID)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(draft.metadata.title.isEmpty ? "Untitled App" : draft.metadata.title).font(.headline)
                                Text("Last saved: \(draft.lastSavedAt.formatted())").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Submission Drafts")
    }
}
