import SwiftUI

struct RadioView: View {
    @StateObject private var viewModel = RadioViewModel()
    @StateObject private var player = RadioPlayerManager.shared
    @State private var showNowPlaying = false
    @State private var showFilters = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                filterChips
                stationList
            }
            .navigationTitle("Radio")
            .navigationBarTitleDisplayMode(.large)
            .safeAreaInset(edge: .bottom) {
                if player.currentStation != nil {
                    radioMiniBar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .sheet(isPresented: $showNowPlaying) {
                NowPlayingRadioView()
            }
            .animation(.spring(response: 0.38, dampingFraction: 0.85),
                       value: player.currentStation != nil)
        }
        .task { viewModel.reload() }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search Stations", text: $viewModel.searchText)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                filterChip(label: "All", icon: "radio", isActive: viewModel.activeFilter == .none) {
                    viewModel.clearFilter()
                }
                filterChip(label: "Nearby", icon: "location.fill", isActive: viewModel.activeFilter == .local) {
                    viewModel.setFilter(viewModel.activeFilter == .local ? .none : .local)
                }
                ForEach(viewModel.popularTags, id: \.self) { tag in
                    let isActive: Bool = viewModel.activeFilter == .tag(tag)
                    filterChip(label: tag.capitalized, icon: nil, isActive: isActive) {
                        viewModel.setFilter(isActive ? .none : .tag(tag))
                    }
                }
                Divider().frame(height: 20)
                ForEach(viewModel.popularCountries, id: \.self) { country in
                    let isActive: Bool = viewModel.activeFilter == .country(country)
                    filterChip(label: country, icon: nil, isActive: isActive) {
                        viewModel.setFilter(isActive ? .none : .country(country))
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private func filterChip(label: String, icon: String?, isActive: Bool,
                             action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                }
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isActive ? Color.accentColor : Color(.secondarySystemBackground),
                        in: Capsule())
            .foregroundColor(isActive ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Station List

    private var stationList: some View {
        Group {
            if viewModel.isLoading && viewModel.stations.isEmpty {
                loadingView
            } else if let error = viewModel.errorMessage, viewModel.stations.isEmpty {
                errorView(message: error)
            } else if viewModel.stations.isEmpty {
                emptyView
            } else {
                List {
                    // Favorites section
                    if !player.favorites.isEmpty && viewModel.searchText.isEmpty
                        && viewModel.activeFilter == .none {
                        Section {
                            ForEach(player.favorites) { station in
                                stationRow(station)
                            }
                        } header: {
                            Text("Favorites")
                        }
                    }

                    // Recently played section
                    if !player.recentlyPlayed.isEmpty && viewModel.searchText.isEmpty
                        && viewModel.activeFilter == .none {
                        Section {
                            ForEach(player.recentlyPlayed.prefix(5)) { station in
                                stationRow(station)
                            }
                        } header: {
                            Text("Recently Played")
                        }
                    }

                    Section(viewModel.searchText.isEmpty ? "Top Stations" : "Results") {
                        ForEach(viewModel.stations) { station in
                            stationRow(station)
                                .onAppear {
                                    if station.id == viewModel.stations.last?.id {
                                        viewModel.loadMore()
                                    }
                                }
                        }
                        if viewModel.hasMore {
                            HStack { Spacer(); ProgressView(); Spacer() }
                                .listRowSeparator(.hidden)
                        }
                    }
                }
                .listStyle(.plain)
                .refreshable { viewModel.reload() }
            }
        }
    }

    @ViewBuilder
    private func stationRow(_ station: RadioStation) -> some View {
        Button {
            player.play(station: station)
            showNowPlaying = true
        } label: {
            HStack(spacing: 12) {
                faviconView(url: station.faviconURL)

                VStack(alignment: .leading, spacing: 3) {
                    Text(station.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        if !station.country.isEmpty {
                            Text(station.country)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        if !station.bitrateLabel.isEmpty {
                            Text(station.bitrateLabel)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        if !station.codec.isEmpty {
                            Text(station.codec.uppercased())
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(.secondary)
                        }
                    }
                    if !station.tagList.isEmpty {
                        Text(station.tagList.joined(separator: " · "))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                if player.currentStation?.id == station.id {
                    Image(systemName: player.isPlaying ? "waveform" : "pause.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.accentColor)
                }

                Button {
                    player.toggleFavorite(station)
                } label: {
                    Image(systemName: player.isFavorite(station) ? "heart.fill" : "heart")
                        .font(.system(size: 15))
                        .foregroundColor(player.isFavorite(station) ? .red : .secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Mini Now Playing Bar

    private var radioMiniBar: some View {
        Button {
            showNowPlaying = true
        } label: {
            HStack(spacing: 12) {
                faviconView(url: player.currentStation?.faviconURL)
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(player.currentStation?.name ?? "")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Text(stateLabel)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    player.togglePlayPause()
                } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.primary)
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 10)
        .padding(.bottom, 6)
    }

    private var stateLabel: String {
        switch player.playbackState {
        case .loading: return "Connecting…"
        case .playing: return "Live"
        case .paused: return "Paused"
        case .error(let msg): return msg
        default: return ""
        }
    }

    // MARK: - State Views

    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView()
            Text("Loading stations…")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("Couldn't load stations")
                .font(.title3.bold())
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Try Again") { viewModel.reload() }
                .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "radio")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No Stations Found")
                .font(.title3.bold())
            Text("Try a different search or filter.")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Favicon

    @ViewBuilder
    private func faviconView(url: URL?) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(width: 44, height: 44)
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFit()
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    default:
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 44, height: 44)
    }
}
