import SwiftUI

struct MyFeedbackView: View {
    @State private var feedbackItems: [Feedback] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            if isLoading {
                ProgressView("Loading...")
            } else if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            } else if feedbackItems.isEmpty {
                ContentUnavailableView(
                    "No Visible Feedback",
                    systemImage: "tray",
                    description: Text("Only submissions with status visibility enabled appear here.")
                )
            } else {
                ForEach(feedbackItems) { feedback in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(feedback.categoryValue.displayName)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.14))
                                .clipShape(Capsule())

                            Text(feedback.statusValue.displayName)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.14))
                                .clipShape(Capsule())

                            Spacer()

                            Text(feedback.createdAt, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Text(feedback.message)
                            .font(.subheadline)
                            .lineLimit(3)

                        if let updatedAt = feedback.lastUpdatedAt {
                            Text("Updated \(updatedAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("My Feedback")
        .task {
            await loadFeedback()
        }
        .refreshable {
            await loadFeedback()
        }
    }

    @MainActor
    private func loadFeedback() async {
        isLoading = true
        errorMessage = nil

        do {
            feedbackItems = try await FeedbackService.shared.fetchMyFeedback()
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }
}
