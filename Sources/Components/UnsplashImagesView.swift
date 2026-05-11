import SwiftUI

struct UnsplashImagesView: View {
    let onSelect: (UnsplashPhoto) -> Void

    @State private var searchText = ""
    @State private var photos: [UnsplashPhoto] = []
    @State private var currentPage = 1
    @State private var totalPages = 0
    @State private var isLoading = false
    @State private var isBackgroundRefreshing = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    private let provider = UnsplashProvider.shared
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    private enum ViewState {
        case empty
        case loading
        case loaded
        case error(String)
    }

    private var viewState: ViewState {
        if let errorMessage, photos.isEmpty {
            return .error(errorMessage)
        }
        if isLoading && photos.isEmpty {
            return .loading
        }
        if photos.isEmpty {
            return .empty
        }
        return .loaded
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                Divider()
                contentArea
            }
            .navigationTitle("Unsplash Images")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search photos…", text: $searchText)
                .textFieldStyle(.plain)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .onSubmit { performSearch() }
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    photos = []
                    errorMessage = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    // MARK: - Content

    @ViewBuilder
    private var contentArea: some View {
        switch viewState {
        case .empty:
            emptyState
        case .loading:
            loadingState
        case .loaded:
            photoGrid
        case .error(let message):
            errorView(message)
        }
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)
            Text("Searching Unsplash…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("Search Unsplash for photos")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36))
                .foregroundStyle(.orange)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Button("Retry") { performSearch() }
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Photo Grid

    private var photoGrid: some View {
        ScrollView {
            if isBackgroundRefreshing {
                HStack(spacing: 6) {
                    ProgressView()
                        .controlSize(.mini)
                    Text("Refreshing…")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 6)
            }

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(photos) { photo in
                    photoCell(photo)
                }
            }
            .padding(8)

            if isLoading {
                ProgressView()
                    .padding()
            } else if currentPage < totalPages {
                Button("Load More") { loadNextPage() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .padding(.bottom, 16)
            }

            if !photos.isEmpty {
                Text("Photos by Unsplash")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.bottom, 8)
            }
        }
    }

    private func photoCell(_ photo: UnsplashPhoto) -> some View {
        Button {
            onSelect(photo)
            dismiss()
        } label: {
            AsyncImage(url: URL(string: photo.urls.small)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    Color.gray.opacity(0.2)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                        }
                case .empty:
                    Color.gray.opacity(0.1)
                        .overlay { ProgressView() }
                @unknown default:
                    Color.gray.opacity(0.1)
                }
            }
            .frame(height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(alignment: .bottomLeading) {
                Text(photo.user.name)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 4))
                    .padding(4)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Search Logic

    private func performSearch() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        errorMessage = nil
        isLoading = true
        isBackgroundRefreshing = false

        Task {
            let result = await provider.search(query: query, page: 1, perPage: 30)
            await MainActor.run {
                isLoading = false
                switch result {
                case .success(let response):
                    photos = response.results
                    totalPages = response.totalPages
                    currentPage = 1
                case .failure(let error):
                    if photos.isEmpty {
                        errorMessage = error.errorDescription
                    }
                }
            }
        }
    }

    private func loadNextPage() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty, !isLoading, currentPage < totalPages else { return }

        isLoading = true
        let nextPage = currentPage + 1

        Task {
            let result = await provider.search(query: query, page: nextPage, perPage: 30)
            await MainActor.run {
                isLoading = false
                switch result {
                case .success(let response):
                    photos.append(contentsOf: response.results)
                    currentPage = nextPage
                    totalPages = response.totalPages
                case .failure(let error):
                    errorMessage = error.errorDescription
                }
            }
        }
    }
}
