import Foundation
import Combine

enum RadioFilter: Equatable {
    case none
    case tag(String)
    case country(String)
    case language(String)
}

@MainActor
final class RadioViewModel: ObservableObject {
    @Published var stations: [RadioStation] = []
    @Published var searchText: String = ""
    @Published var activeFilter: RadioFilter = .none
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var hasMore: Bool = true

    private var currentOffset: Int = 0
    private let pageSize = 30
    private var searchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    let popularTags = ["pop", "rock", "jazz", "classical", "news", "talk", "electronic",
                       "hip-hop", "country", "r&b", "latin", "reggae", "blues", "metal"]
    let popularCountries = ["United States", "United Kingdom", "Germany", "France",
                            "Canada", "Australia", "Brazil", "Japan"]
    let popularLanguages = ["english", "german", "french", "spanish", "portuguese",
                            "italian", "japanese", "arabic"]

    init() {
        $searchText
            .debounce(for: .milliseconds(350), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.reload()
            }
            .store(in: &cancellables)
    }

    // MARK: - Load

    func reload() {
        currentOffset = 0
        stations = []
        hasMore = true
        errorMessage = nil
        loadPage()
    }

    func loadMore() {
        guard !isLoading, hasMore else { return }
        loadPage()
    }

    private func loadPage() {
        searchTask?.cancel()
        let query = searchText.trimmingCharacters(in: .whitespaces)
        let offset = currentOffset
        let filter = activeFilter
        let limit = pageSize

        isLoading = true
        searchTask = Task {
            do {
                let result: [RadioStation]
                if !query.isEmpty {
                    result = try await RadioService.shared.searchStations(
                        query: query, offset: offset, limit: limit)
                } else {
                    switch filter {
                    case .none:
                        result = try await RadioService.shared.fetchTopStations(
                            offset: offset, limit: limit)
                    case .tag(let t):
                        result = try await RadioService.shared.fetchByTag(
                            tag: t, offset: offset, limit: limit)
                    case .country(let c):
                        result = try await RadioService.shared.fetchByCountry(
                            country: c, offset: offset, limit: limit)
                    case .language(let l):
                        result = try await RadioService.shared.fetchByLanguage(
                            language: l, offset: offset, limit: limit)
                    }
                }
                guard !Task.isCancelled else { return }
                if offset == 0 {
                    stations = result
                } else {
                    stations += result
                }
                hasMore = result.count == limit
                currentOffset += result.count
                errorMessage = nil
            } catch {
                guard !Task.isCancelled else { return }
                errorMessage = error.localizedDescription
                InternalLogger.shared.log(
                    "RadioViewModel: API error — \(error.localizedDescription)", level: .error)
            }
            isLoading = false
        }
    }

    func setFilter(_ filter: RadioFilter) {
        activeFilter = filter
        searchText = ""
        reload()
    }

    func clearFilter() {
        activeFilter = .none
        reload()
    }
}
