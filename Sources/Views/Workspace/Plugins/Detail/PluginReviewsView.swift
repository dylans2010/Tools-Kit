import SwiftUI

struct PluginReviewsView: View {
    let plugin: PluginDefinition
    @State private var reviews: [PluginReview] = []
    @State private var newRating = 5
    @State private var newComment = ""
    @State private var showingComposeSheet = false

    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Text(String(format: "%.1f", averageRating))
                        .font(.system(size: 48, weight: .bold))
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= Int(averageRating.rounded()) ? "star.fill" : "star")
                                .foregroundStyle(.yellow)
                        }
                    }
                    Text("\(reviews.count) Reviews")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Rating Distribution") {
                ForEach((1...5).reversed(), id: \.self) { rating in
                    HStack {
                        Text("\(rating)")
                            .font(.caption)
                            .frame(width: 16)
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(.blue.opacity(0.3))
                                .frame(width: geo.size.width * ratingPercentage(rating))
                        }
                        .frame(height: 8)
                        Text("\(ratingCount(rating))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(width: 24, alignment: .trailing)
                    }
                }
            }

            Section("Reviews") {
                if reviews.isEmpty {
                    ContentUnavailableView("No Reviews Yet", systemImage: "text.bubble", description: Text("Be the first to review this plugin."))
                } else {
                    ForEach(reviews) { review in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                HStack(spacing: 2) {
                                    ForEach(1...5, id: \.self) { star in
                                        Image(systemName: star <= review.rating ? "star.fill" : "star")
                                            .font(.caption2)
                                            .foregroundStyle(.yellow)
                                    }
                                }
                                Spacer()
                                Text(review.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Text(review.author)
                                .font(.subheadline.bold())
                            Text(review.comment)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Reviews")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingComposeSheet = true
                } label: {
                    Label("Write Review", systemImage: "square.and.pencil")
                }
            }
        }
        .sheet(isPresented: $showingComposeSheet) {
            NavigationStack {
                Form {
                    Section("Rating") {
                        Picker("Stars", selection: $newRating) {
                            ForEach(1...5, id: \.self) { Text("\($0) stars").tag($0) }
                        }
                    }
                    Section("Comment") {
                        TextEditor(text: $newComment)
                            .frame(minHeight: 100)
                    }
                }
                .navigationTitle("Write Review")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingComposeSheet = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Submit") {
                            submitReview()
                            showingComposeSheet = false
                        }
                        .disabled(newComment.isEmpty)
                    }
                }
            }
        }
        .task { loadReviews() }
    }

    private var averageRating: Double {
        guard !reviews.isEmpty else { return 0 }
        return Double(reviews.reduce(0) { $0 + $1.rating }) / Double(reviews.count)
    }

    private func ratingCount(_ rating: Int) -> Int {
        reviews.count(where: { $0.rating == rating })
    }

    private func ratingPercentage(_ rating: Int) -> Double {
        guard !reviews.isEmpty else { return 0 }
        return Double(ratingCount(rating)) / Double(reviews.count)
    }

    private func submitReview() {
        reviews.insert(PluginReview(author: "You", rating: newRating, comment: newComment, date: Date()), at: 0)
        newRating = 5
        newComment = ""
    }

    private func loadReviews() {
        // Reviews are user-submitted; start empty until users write their own.
    }
}

private struct PluginReview: Identifiable {
    let id = UUID()
    let author: String
    let rating: Int
    let comment: String
    let date: Date
}
