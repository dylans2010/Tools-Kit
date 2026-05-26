import SwiftUI

struct CalendarAvailabilityHeatmapView: View {
    @StateObject private var manager = CalendarManager.shared
    @State private var selectedWeek = Date()
    private let calendar = Calendar.current

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Weekly Availability Heatmap")
                    .font(.headline)
                    .padding(.horizontal)

                heatmapGrid
                    .padding()

                legend
                    .padding(.horizontal)

                insightsSection
                    .padding()
            }
        }
        .navigationTitle("Availability")
    }

    private var heatmapGrid: some View {
        let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let hours = Array(8...20) // 8 AM to 8 PM

        return VStack(spacing: 8) {
            HStack(spacing: 8) {
                Spacer().frame(width: 40)
                ForEach(days, id: \.self) { day in
                    Text(day).font(.caption2.bold()).frame(maxWidth: .infinity)
                }
            }

            ForEach(hours, id: \.self) { hour in
                HStack(spacing: 8) {
                    Text("\(hour)").font(.system(size: 8, weight: .bold)).frame(width: 40, alignment: .trailing)
                    ForEach(0..<7, id: \.self) { dayOffset in
                        let intensity = getIntensity(dayOffset: dayOffset, hour: hour)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(intensityColor(intensity))
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
    }

    private var legend: some View {
        HStack(spacing: 12) {
            Text("Free").font(.caption2).foregroundStyle(.secondary)
            ForEach(0...4, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(intensityColor(Double(i) / 4.0))
                    .frame(width: 12, height: 12)
            }
            Text("Busy").font(.caption2).foregroundStyle(.secondary)
        }
    }

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Schedule Insights", systemImage: "sparkles")
                .font(.subheadline.bold())

            VStack(alignment: .leading, spacing: 8) {
                InsightRow(icon: "clock.badge.checkmark", text: "Optimal focus time identified on Tuesday mornings.")
                InsightRow(icon: "exclamationmark.bubble", text: "Potential burnout risk detected on Thursday afternoon.")
                InsightRow(icon: "calendar.badge.plus", text: "Suggest moving lunch meetings to increase deep work.")
            }
        }
        .padding()
        .background(Color.accentColor.opacity(0.05), in: RoundedRectangle(cornerRadius: 15))
    }

    private func getIntensity(dayOffset: Int, hour: Int) -> Double {
        // Real logic using CalendarManager events
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedWeek))!
        let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)!
        let events = manager.events(on: date)

        let busyEvents = events.filter {
            let components = calendar.dateComponents([.hour], from: $0.startTime)
            return components.hour == hour
        }

        return min(1.0, Double(busyEvents.count) * 0.5)
    }

    private func intensityColor(_ intensity: Double) -> Color {
        if intensity == 0 { return Color(.secondarySystemBackground) }
        return Color.blue.opacity(intensity)
    }
}

private struct InsightRow: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundStyle(.blue).font(.caption)
            Text(text).font(.caption).foregroundStyle(.secondary)
        }
    }
}
