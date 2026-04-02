import SwiftUI
import WeatherKit
import CoreLocation

class WeatherViewModel: ObservableObject {
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
            self?.fetchWeather(for: location)
            self?.fetchLocationName(for: location)
        }

        weatherManager.onAuthorizationChange = { [weak self] status in
            DispatchQueue.main.async {
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
        Task {
            do {
                let weather = try await weatherManager.fetchWeather(for: location)
                let transformed = repository.transform(weather: weather)
                DispatchQueue.main.async {
                    self.weatherData = transformed
                    self.repository.saveToCache(transformed)
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    private func fetchLocationName(for location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            if let city = placemarks?.first?.locality {
                DispatchQueue.main.async {
                    self?.locationName = city
                }
            }
        }
    }
}
