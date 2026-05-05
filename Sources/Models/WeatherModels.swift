import Foundation
import WeatherKit

struct CurrentWeatherModel: Codable {
    let temperature: Double
    let condition: String
    let conditionIcon: String
    let highTemperature: Double
    let lowTemperature: Double
    let feelsLike: Double
    let humidity: Double
    let windSpeed: Double
    let uvIndex: Int
    let visibility: Double
    let pressure: Double
}

struct HourlyForecastModel: Codable, Identifiable {
    let id = UUID()
    let date: Date
    let temperature: Double
    let conditionIcon: String
    let precipitationProbability: Double
}

struct DailyForecastModel: Codable, Identifiable {
    let id = UUID()
    let date: Date
    let highTemperature: Double
    let lowTemperature: Double
    let conditionIcon: String
}

struct WeatherInsight: Codable, Identifiable {
    var id = UUID()
    let title: String
    let description: String
    let type: WeatherInsightType
}

enum WeatherInsightType: String, Codable {
    case rain
    case temperature
    case uv
    case generic
}

struct FullWeatherData: Codable {
    let current: CurrentWeatherModel
    let hourly: [HourlyForecastModel]
    let daily: [DailyForecastModel]
    let insights: [WeatherInsight]
}
