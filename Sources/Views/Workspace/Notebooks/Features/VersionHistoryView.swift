import SwiftUI

struct VersionHistoryView: View {
    let pageID: UUID
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = TimeTravelManager.shared

    var body: some View {
        NavigationStack {
            List {
                let snapshots = manager.snapshots.filter { $0.entityID == pageID }
                if snapshots.isEmpty {
                    Text("No version history found for this page.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(snapshots.reversed()) { snapshot in
                        VStack(alignment: .leading) {
                            Text(snapshot.message)
                                .font(.subheadline.bold())
                            Text(snapshot.timestamp, style: .relative)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Version History")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
