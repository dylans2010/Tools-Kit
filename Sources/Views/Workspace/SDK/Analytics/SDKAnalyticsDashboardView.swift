import SwiftUI

struct SDKAnalyticsDashboardView: View {
    @StateObject private var analytics = SDKAnalyticsEngine.shared
    @State private var selectedCategory: AnalyticsCategory?

    var displayedEvents: [AnalyticsEvent] {
        if let category = selectedCategory {
            return analytics.events(for: category)
        }
        return analytics.recentEvents(limit: 100)
    }

    var body: some View {
        List {
            Section("Session Metrics") {
                HStack(spacing: 12) {
                    metricCard(title: "Total", value: "\(analytics.sessionMetrics.totalEvents)", color: .blue)
                    metricCard(title: "Errors", value: "\(analytics.sessionMetrics.errorCount)", color: .red)
                    metricCard(title: "API", value: "\(analytics.sessionMetrics.apiCount)", color: .green)
                }
            }

            Section("Categories") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        categoryChip(nil, label: "All (\(analytics.events.count))")
                        ForEach(AnalyticsCategory.allCases, id: \.self) { cat in
                            categoryChip(cat, label: "\(cat.rawValue.capitalized) (\(analytics.eventCount(for: cat)))")
                        }
                    }
                }
            }

            Section("Events (\(displayedEvents.count))") {
                if displayedEvents.isEmpty {
                    ContentUnavailableView("No Events", systemImage: "chart.bar.xaxis", description: Text("Analytics events will appear here once tracking starts."))
                } else {
                    ForEach(displayedEvents) { event in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(event.name)
                                    .font(.subheadline.bold())
                                Spacer()
                                Text(event.category.rawValue)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                            if !event.properties.isEmpty {
                                HStack {
                                    ForEach(Array(event.properties.keys.sorted().prefix(3)), id: \.self) { key in
                                        Text("\(key): \(event.properties[key] ?? "")")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            Text(event.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Controls") {
                HStack {
                    Button(analytics.isTracking ? "Stop Tracking" : "Start Tracking") {
                        if analytics.isTracking { analytics.stopTracking() } else { analytics.startTracking() }
                    }
                    .buttonStyle(.bordered)
                    Spacer()
                    Button("Flush") {
                        _ = analytics.flush()
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            }
        }
        .navigationTitle("SDK Analytics")
    }

    private func metricCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title2.bold()).foregroundStyle(color)
            Text(title).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func categoryChip(_ category: AnalyticsCategory?, label: String) -> some View {
        Button { selectedCategory = category } label: {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(selectedCategory == category ? Color.blue : Color(.secondarySystemBackground))
                .foregroundStyle(selectedCategory == category ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}
