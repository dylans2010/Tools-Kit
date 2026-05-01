import SwiftUI

struct WeatherView: View {
    @StateObject private var viewModel = WeatherViewModel()

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    headerSection

                    if let weather = viewModel.weatherData {
                        insightsSection(weather.insights)
                        hourlySection(weather.hourly)
                        dailySection(weather.daily)
                        detailsGrid(weather.current)
                    } else if viewModel.isLoading {
                        ProgressView()
                            .padding(.top, 100)
                    } else if let error = viewModel.errorMessage {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                            Text(error)
                                .multilineTextAlignment(.center)
                            Button("Try Again") {
                                viewModel.refresh()
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.top, 100)
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "location.slash")
                                .font(.largeTitle)
                            Text("Location access required to show local weather.")
                                .multilineTextAlignment(.center)
                            Button("Allow Access") {
                                viewModel.refresh()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.top, 100)
                    }
                }
                .padding()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            viewModel.refresh()
        }
    }

    private var backgroundGradient: some View {
        let colors: [Color]
        if let condition = viewModel.weatherData?.current.conditionIcon {
            if condition.contains("sun") {
                colors = [Color.blue, Color(red: 0.4, green: 0.6, blue: 0.9)]
            } else if condition.contains("cloud") {
                colors = [Color.gray, Color(red: 0.5, green: 0.5, blue: 0.6)]
            } else if condition.contains("rain") || condition.contains("snow") {
                colors = [Color(red: 0.2, green: 0.3, blue: 0.4), Color(red: 0.4, green: 0.5, blue: 0.6)]
            } else {
                colors = [Color.blue, Color.purple]
            }
        } else {
            colors = [Color.blue, Color.cyan]
        }

        return LinearGradient(gradient: Gradient(colors: colors), startPoint: .top, endPoint: .bottom)
    }

    private var headerSection: some View {
        VStack(spacing: 4) {
            Text(viewModel.locationName)
                .font(.system(size: 32, weight: .medium))

            if let current = viewModel.weatherData?.current {
                Text("\(Int(current.temperature))°")
                    .font(.system(size: 96, weight: .thin))

                Text(current.condition)
                    .font(.title3)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    Text("H:\(Int(current.highTemperature))°")
                    Text("L:\(Int(current.lowTemperature))°")
                }
                .font(.headline)
            }
        }
        .foregroundColor(.white)
        .padding(.top, 20)
    }

    private func insightsSection(_ insights: [WeatherInsight]) -> some View {
        Group {
            if !insights.isEmpty {
                VStack(spacing: 12) {
                    ForEach(insights) { insight in
                        InsightCard(insight: insight)
                    }
                }
            }
        }
    }

    private func hourlySection(_ hourly: [HourlyForecastModel]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Hourly Forecast", systemImage: "clock")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white.opacity(0.8))
                .padding(.leading, 8)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(hourly) { hour in
                        HourlyForecastRow(hour: hour)
                    }
                }
                .padding()
            }
            .background(Color.black.opacity(0.1))
            .cornerRadius(16)
        }
    }

    private func dailySection(_ daily: [DailyForecastModel]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("10-Day Forecast", systemImage: "calendar")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white.opacity(0.8))
                .padding(.leading, 8)

            VStack(spacing: 0) {
                ForEach(daily) { day in
                    DailyForecastRow(day: day)
                    if day.id != daily.last?.id {
                        Divider()
                            .background(Color.white.opacity(0.2))
                    }
                }
            }
            .padding()
            .background(Color.black.opacity(0.1))
            .cornerRadius(16)
        }
    }

    private func detailsGrid(_ current: CurrentWeatherModel) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            WeatherCard(title: "UV INDEX", value: "\(current.uvIndex)", icon: "sun.max.fill", subtitle: uvDescription(current.uvIndex))
            WeatherCard(title: "WIND", value: "\(Int(current.windSpeed)) km/h", icon: "wind", subtitle: nil)
            WeatherCard(title: "HUMIDITY", value: "\(Int(current.humidity * 100))%", icon: "humidity.fill", subtitle: "The dew point is \(Int(current.temperature - ((1 - current.humidity) * 5)))° right now.")
            WeatherCard(title: "FEELS LIKE", value: "\(Int(current.feelsLike))°", icon: "thermometer.medium", subtitle: nil)
            WeatherCard(title: "VISIBILITY", value: "\(Int(current.visibility / 1000)) km", icon: "eye.fill", subtitle: nil)
            WeatherCard(title: "PRESSURE", value: "\(Int(current.pressure)) hPa", icon: "gauge.with.needle", subtitle: nil)
        }
    }

    private func uvDescription(_ index: Int) -> String {
        if index <= 2 { return "Low" }
        if index <= 5 { return "Moderate" }
        if index <= 7 { return "High" }
        if index <= 10 { return "Very High" }
        return "Extreme"
    }
}

struct WeatherTool: Tool {
    let name = "Weather"
    let icon = "cloud.sun.fill"
    let category = ToolCategory.general
    let complexity = ToolComplexity.basic
    let description = "Real-time weather with 10-day forecast and insights"
    let requiresAPI = true
    var view: AnyView { AnyView(WeatherView()) }
}
