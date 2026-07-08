import Foundation
#if canImport(CoreLocation)
import CoreLocation
#endif

/// Discovers local radio stations using CoreLocation + Radio Browser API.
@MainActor
final class LocalRadioService: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocalRadioService()

    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var countryCode: String? = nil

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?

    override private init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        authorizationStatus = locationManager.authorizationStatus
    }

    // MARK: - Public

    /// Request location permission and determine country code.
    func requestLocation() async {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            try? await Task.sleep(nanoseconds: 500_000_000)
        default:
            break
        }

        let location = await withCheckedContinuation { continuation in
            locationContinuation = continuation
            locationManager.requestLocation()
        }

        if let loc = location {
            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(loc)
                countryCode = placemarks.first?.isoCountryCode
            } catch {
                InternalLogger.shared.log("LocalRadioService: geocode failed — \(error.localizedDescription)", level: .warning)
                countryCode = Locale.current.regionCode
            }
        } else {
            InternalLogger.shared.log("LocalRadioService: location unavailable, using device locale", level: .info)
            countryCode = Locale.current.regionCode
        }
    }

    /// Fetch local stations for the determined country.
    func fetchLocalStations(limit: Int = 50) async throws -> [RadioStation] {
        if countryCode == nil { await requestLocation() }
        guard let code = countryCode else { return [] }

        let countryName = Locale.current.localizedString(forRegionCode: code) ?? code

        do {
            let byCountry = try await RadioService.shared.fetchByCountry(country: countryName, offset: 0, limit: limit)
            if !byCountry.isEmpty { return byCountry }
            return try await RadioService.shared.searchStations(query: code, offset: 0, limit: limit)
        } catch {
            InternalLogger.shared.log("LocalRadioService: fetch failed — \(error.localizedDescription)", level: .error)
            throw error
        }
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        Task { @MainActor in
            self.locationContinuation?.resume(returning: location)
            self.locationContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        InternalLogger.shared.log("LocalRadioService: location error — \(error.localizedDescription)", level: .warning)
        Task { @MainActor in
            self.locationContinuation?.resume(returning: nil)
            self.locationContinuation = nil
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
        }
    }
}
