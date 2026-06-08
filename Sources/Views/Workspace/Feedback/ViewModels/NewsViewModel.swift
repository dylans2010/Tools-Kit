import Foundation
import Combine

@MainActor
public final class NewsViewModel: ObservableObject {
    @Published public var newsItems: [FeedbackNews] = []
    @Published public var isLoading = false

    public init() {}

    public func fetchNews() async {
        isLoading = true
        newsItems = await FeedbackService.shared.fetchNews()
        isLoading = false
    }
}
