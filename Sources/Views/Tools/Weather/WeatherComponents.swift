import SwiftUI

struct WeatherCard: View {
    let title: String
    let value: String
    let icon: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(value)
                .font(.title2)
                .fontWeight(.semibold)

            if let subtitle = subtitle {
                Spacer()
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

struct HourlyForecastRow: View {
    let hour: HourlyForecastModel

    var body: some View {
        VStack(spacing: 8) {
            Text(formatDate(hour.date))
                .font(.caption)
            Image(systemName: hour.conditionIcon)
                .symbolVariant(.fill)
                .foregroundStyle(.blue)
                .font(.title3)
            Text("\(Int(hour.temperature))°")
                .font(.subheadline)
                .fontWeight(.medium)
            if hour.precipitationProbability > 0 {
                Text("\(Int(hour.precipitationProbability * 100))%")
                    .font(.system(size: 10))
                    .foregroundColor(.blue)
            }
        }
        .frame(width: 60)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        return formatter.string(from: date)
    }
}

struct DailyForecastRow: View {
    let day: DailyForecastModel

    var body: some View {
        HStack {
            Text(formatDate(day.date))
                .font(.body)
                .frame(width: 60, alignment: .leading)

            Spacer()

            Image(systemName: day.conditionIcon)
                .symbolVariant(.fill)
                .foregroundStyle(.blue)
                .font(.title3)
                .frame(width: 40)

            Spacer()

            HStack(spacing: 12) {
                Text("\(Int(day.lowTemperature))°")
                    .foregroundColor(.secondary)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 80, height: 4)

                    // Simplified temperature bar
                    Capsule()
                        .fill(LinearGradient(colors: [.blue, .orange], startPoint: .leading, endPoint: .trailing))
                        .frame(width: 40, height: 4)
                        .offset(x: 20)
                }

                Text("\(Int(day.highTemperature))°")
            }
            .font(.body.monospacedDigit())
        }
        .padding(.vertical, 8)
    }

    private func formatDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Today" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

struct InsightCard: View {
    let insight: WeatherInsight

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconForType(insight.type))
                .font(.title2)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.headline)
                Text(insight.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(16)
    }

    private func iconForType(_ type: WeatherInsightType) -> String {
        switch type {
        case .rain: return "cloud.rain.fill"
        case .temperature: return "thermometer.medium"
        case .uv: return "sun.max.fill"
        case .generic: return "info.circle.fill"
        }
    }
}
