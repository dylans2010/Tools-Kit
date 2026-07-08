import Foundation
#if canImport(WeatherKit)
import WeatherKit
#endif
#if canImport(CoreLocation)
import CoreLocation
#endif

class WeatherKitManager: NSObject, CLLocationManagerDelegate {
    private let weatherProvider = WeatherService.shared
    private let locationManager = CLLocationManager()

    var onLocationUpdate: ((CLLocation) -> Void)?
    var onAuthorizationChange: ((CLAuthorizationStatus) -> Void)?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func fetchWeather(for location: CLLocation) async throws -> Weather {
        return try await weatherProvider.weather(for: location)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        onLocationUpdate?(location)
        locationManager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        onAuthorizationChange?(status)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}
