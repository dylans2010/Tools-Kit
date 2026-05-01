import SwiftUI

struct PRListView: View {
    @StateObject private var prManager = PRManager.shared
    let spaceID: UUID

    var body: some View {
        List(prManager.pullRequests.filter { $0.spaceID == spaceID }) { pr in
            NavigationLink(destination: PRDetailView(pr: pr)) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(pr.title)
                        .font(.headline)
                    HStack {
                        Text("#\(pr.id.uuidString.prefix(6))")
                        Text("by \(pr.authorName)")
                        Spacer()
                        PRStatusBadge(status: pr.status)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Pull Requests")
    }
}

struct PRStatusBadge: View {
    let status: PRStatus

    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(backgroundColor.opacity(0.2))
            .foregroundColor(backgroundColor)
            .cornerRadius(4)
    }

    private var backgroundColor: Color {
        switch status {
        case .open: return .green
        case .merged: return .purple
        case .closed: return .red
        case .draft: return .gray
        }
    }
}
