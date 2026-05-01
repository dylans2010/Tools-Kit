import SwiftUI

struct PRDetailView: View {
    @State var pr: PullRequest
    @State private var showingDiff = false
    @State private var showingConflictResolution = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(pr.title)
                        .font(.title2.bold())

                    HStack {
                        PRStatusBadge(status: pr.status)
                        Text("\(pr.authorName) wants to merge into target branch")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)

                // Actions
                HStack(spacing: 12) {
                    Button(action: { showingDiff.toggle() }) {
                        Label("Files Changed", systemImage: "doc.on.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button(action: { /* Approve logic */ }) {
                        Label("Approve", systemImage: "checkmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
                .padding(.horizontal)

                // Description
                WorkspaceSurfaceCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        Text(pr.description)
                            .font(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)

                // Conversation
                VStack(alignment: .leading, spacing: 16) {
                    Text("Conversation")
                        .font(.headline)

                    ForEach(pr.comments) { comment in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(comment.authorName).bold()
                                Text(comment.timestamp, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Text(comment.content)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .shadow(radius: 1)
                    }
                }
                .padding(.horizontal)
            }
        }
        .sheet(isPresented: $showingDiff) {
            SideBySideDiffView()
        }
        .navigationTitle("PR #\(pr.id.uuidString.prefix(6))")
        .navigationBarTitleDisplayMode(.inline)
    }
}
