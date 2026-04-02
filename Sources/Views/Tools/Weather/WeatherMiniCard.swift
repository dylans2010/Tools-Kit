import SwiftUI

struct WeatherMiniCard: View {
    @StateObject private var viewModel = WeatherViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.locationName)
                        .font(.headline)
                        .foregroundColor(.white)

                    if let current = viewModel.weatherData?.current {
                        Text("\(Int(current.temperature))°")
                            .font(.system(size: 36, weight: .thin))
                            .foregroundColor(.white)
                    }
                }

                Spacer()

                if let current = viewModel.weatherData?.current {
                    VStack(alignment: .trailing, spacing: 4) {
                        Image(systemName: current.conditionIcon)
                            .symbolVariant(.fill)
                            .font(.system(size: 32))
                            .foregroundStyle(.white)

                        Text(current.condition)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                } else if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                }
            }

            if let current = viewModel.weatherData?.current {
                HStack {
                    Text("H:\(Int(current.highTemperature))°")
                    Text("L:\(Int(current.lowTemperature))°")
                    Spacer()
                    if let nextRain = viewModel.weatherData?.insights.first(where: { $0.type == .rain }) {
                        Text(nextRain.title)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                backgroundGradient
                if let current = viewModel.weatherData?.current {
                    // Subtle icon background
                    Image(systemName: current.conditionIcon)
                        .font(.system(size: 100))
                        .foregroundColor(.white.opacity(0.1))
                        .offset(x: 100, y: 20)
                }
            }
        )
        .cornerRadius(20)
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

        return LinearGradient(gradient: Gradient(colors: colors), startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
