import SwiftUI

public struct FeedbackNewsView: View {
    @StateObject private var viewModel = NewsViewModel()

    public init() {}

    public var body: some View {
        List {
            ForEach(viewModel.newsItems) { item in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(item.title)
                            .font(.headline)
                        Spacer()
                        Text(item.type.rawValue.uppercased())
                            .font(.system(size: 8, weight: .bold))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(newsColor(for: item.type).opacity(0.1))
                            .foregroundColor(newsColor(for: item.type))
                            .cornerRadius(4)
                    }

                    Text(item.body)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(item.date.formatted(date: .long, time: .omitted))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 5)
            }
        }
        .navigationTitle("News & Updates")
        .task {
            await viewModel.fetchNews()
        }
    }

    private func newsColor(for type: FeedbackNews.NewsType) -> Color {
        switch type {
        case .update: return .blue
        case .fix: return .green
        case .announcement: return .orange
        }
    }
}
