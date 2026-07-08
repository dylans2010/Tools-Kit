import SwiftUI
#if canImport(WeatherKit)
import WeatherKit
#endif
#if canImport(CoreLocation)
import CoreLocation
#endif

@MainActor
final class WeatherViewModel: ObservableObject {
    @Published var weatherData: FullWeatherData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var locationName: String = "Current Location"
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let weatherManager = WeatherKitManager()
    private let repository = WeatherRepository()
    private let geocoder = CLGeocoder()

    init() {
        weatherManager.onLocationUpdate = { [weak self] location in
            Task { @MainActor in
                self?.fetchWeather(for: location)
                self?.fetchLocationName(for: location)
            }
        }

        weatherManager.onAuthorizationChange = { [weak self] status in
            Task { @MainActor in
                self?.authorizationStatus = status
                if status == .authorizedWhenInUse || status == .authorizedAlways {
                    self?.refresh()
                }
            }
        }

        self.weatherData = repository.loadFromCache()
    }

    func refresh() {
        isLoading = true
        weatherManager.requestLocation()
    }

    private func fetchWeather(for location: CLLocation) {
        Task { @MainActor in
            do {
                let weather = try await weatherManager.fetchWeather(for: location)
                let transformed = repository.transform(weather: weather)
                self.weatherData = transformed
                self.repository.saveToCache(transformed)
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    private func fetchLocationName(for location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            if let city = placemarks?.first?.locality {
                Task { @MainActor in
                    self?.locationName = city
                }
            }
        }
    }
}
