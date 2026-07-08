import Foundation
#if canImport(WeatherKit)
import WeatherKit
#endif
#if canImport(CoreLocation)
import CoreLocation
#endif

class WeatherRepository {
    private let cacheKey = "cached_weather_data"

    func saveToCache(_ data: FullWeatherData) {
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
        }
    }

    func loadFromCache() -> FullWeatherData? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else { return nil }
        return try? JSONDecoder().decode(FullWeatherData.self, from: data)
    }

    func transform(weather: Weather) -> FullWeatherData {
        let current = weather.currentWeather

        let currentModel = CurrentWeatherModel(
            temperature: current.temperature.value,
            condition: current.condition.description,
            conditionIcon: current.symbolName,
            highTemperature: weather.dailyForecast.first?.highTemperature.value ?? current.temperature.value,
            lowTemperature: weather.dailyForecast.first?.lowTemperature.value ?? current.temperature.value,
            feelsLike: current.apparentTemperature.value,
            humidity: current.humidity,
            windSpeed: current.wind.speed.value,
            uvIndex: current.uvIndex.value,
            visibility: current.visibility.value,
            pressure: current.pressure.value
        )

        let hourlyModels = weather.hourlyForecast.prefix(24).map { hour in
            HourlyForecastModel(
                date: hour.date,
                temperature: hour.temperature.value,
                conditionIcon: hour.symbolName,
                precipitationProbability: hour.precipitationChance
            )
        }

        let dailyModels = weather.dailyForecast.prefix(10).map { day in
            DailyForecastModel(
                date: day.date,
                highTemperature: day.highTemperature.value,
                lowTemperature: day.lowTemperature.value,
                conditionIcon: day.symbolName
            )
        }

        let insights = generateInsights(weather: weather)

        return FullWeatherData(
            current: currentModel,
            hourly: Array(hourlyModels),
            daily: Array(dailyModels),
            insights: insights
        )
    }

    private func generateInsights(weather: Weather) -> [WeatherInsight] {
        var insights: [WeatherInsight] = []

        // Rain insight
        let rainChance = weather.hourlyForecast.prefix(6).map { $0.precipitationChance }.max() ?? 0
        if rainChance > 0.3 {
            insights.append(WeatherInsight(
                title: "Rain Expected",
                description: "There's a \(Int(rainChance * 100))% chance of rain in the next few hours.",
                type: .rain
            ))
        }

        // UV insight
        if weather.currentWeather.uvIndex.value >= 6 {
            insights.append(WeatherInsight(
                title: "High UV Index",
                description: "The UV index is high. Wear sunscreen if you're going outside.",
                type: .uv
            ))
        }

        // Temperature drop
        if let first = weather.hourlyForecast.first?.temperature.value,
           let later = weather.hourlyForecast.dropFirst(4).first?.temperature.value,
           first - later > 5 {
            insights.append(WeatherInsight(
                title: "Temperature Drop",
                description: "It will get significantly cooler in the next few hours.",
                type: .temperature
            ))
        }

        return insights
    }
}
