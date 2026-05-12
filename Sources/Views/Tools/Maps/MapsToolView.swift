import SwiftUI
import MapKit

struct MapsToolView: View {
    @StateObject private var viewModel = MapsToolViewModel()

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            if !viewModel.savedLocations.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(viewModel.savedLocations) { location in
                            Button(location.name) {
                                viewModel.region.center = location.coordinate
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 6)
                }
            }

            ZStack {
                Map(coordinateRegion: $viewModel.region, annotationItems: viewModel.searchResults) { item in
                    MapMarker(coordinate: item.mapItem.placemark.coordinate)
                }
                .ignoresSafeArea(edges: .bottom)

                if !viewModel.searchResults.isEmpty {
                    searchResultsList
                }
            }
        }
        .navigationTitle("Latina Finder")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var searchBar: some View {
        HStack {
            TextField("Search For Latinas", text: $viewModel.searchText)
                .textFieldStyle(.roundedBorder)
                .onSubmit { viewModel.search() }

            Button(action: viewModel.search) {
                if viewModel.isSearching {
                    ProgressView()
                } else {
                    Image(systemName: "magnifyingglass")
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }

    private var searchResultsList: some View {
        VStack {
            Spacer()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.searchResults) { item in
                        let mapItem = item.mapItem
                        VStack(alignment: .leading) {
                            Text(mapItem.name ?? "Unknown")
                                .font(.headline)
                                .lineLimit(1)
                            Text(mapItem.placemark.title ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)

                            HStack {
                                Button("Go") { viewModel.selectItem(mapItem) }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)

                                Button(action: { viewModel.saveLocation(mapItem) }) {
                                    Image(systemName: "star")
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                        .padding()
                        .frame(width: 200)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 3)
                    }
                }
                .padding()
            }
            .background(.ultraThinMaterial)
        }
    }
}

struct MapsTool: Tool, Sendable {
    let name = "Maps Tool"
    let icon = "map.fill"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.advanced
    let description = "Search, pins, and navigation powered by MapKit"
    let requiresAPI = true

    var view: AnyView {
        AnyView(MapsToolView())
    }
}
