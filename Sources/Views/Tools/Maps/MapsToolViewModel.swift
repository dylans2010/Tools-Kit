import Foundation
import MapKit
import SwiftUI

class MapsToolViewModel: ObservableObject {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @Published var searchText = ""
    @Published var searchResults: [IdentifiableMapItem] = []
    @Published var savedLocations: [MapLocation] = []
    @Published var route: MKRoute?
    @Published var isSearching = false

    private let mapsService = MapsService()

    func search() {
        guard !searchText.isEmpty else { return }
        isSearching = true
        Task {
            do {
                let items = try await mapsService.search(query: searchText)
                DispatchQueue.main.async {
                    self.searchResults = items.map { IdentifiableMapItem(mapItem: $0) }
                    self.isSearching = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isSearching = false
                }
            }
        }
    }

    func saveLocation(_ item: MKMapItem) {
        let location = MapLocation(name: item.name ?? "Unknown", coordinate: item.placemark.coordinate)
        savedLocations.append(location)
    }

    func selectItem(_ item: MKMapItem) {
        region = MKCoordinateRegion(
            center: item.placemark.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }
}
