import Foundation
import MapKit

struct MapLocation: Identifiable, Codable, Sendable {
    let id: UUID
    let name: String
    let coordinate: CLLocationCoordinate2D

    enum CodingKeys: String, CodingKey, Sendable {
        case id, name, latitude, longitude
    }

    init(id: UUID = UUID(), name: String, coordinate: CLLocationCoordinate2D) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        let lat = try container.decode(Double.self, forKey: .latitude)
        let lon = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
    }
}

struct IdentifiableMapItem: Identifiable, Sendable {
    let id = UUID()
    let mapItem: MKMapItem
}

class MapsService {
    func search(query: String) async throws -> [MKMapItem] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        return response.mapItems
    }

    func calculateRoute(from: MKMapItem, to: MKMapItem) async throws -> MKRoute? {
        let request = MKDirections.Request()
        request.source = from
        request.destination = to
        request.transportType = .automobile

        let directions = MKDirections(request: request)
        let response = try await directions.calculate()
        return response.routes.first
    }
}
