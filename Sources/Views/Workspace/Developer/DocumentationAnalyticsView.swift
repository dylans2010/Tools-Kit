import SwiftUI

struct DocumentationAnalyticsView: View {
    @ObservedObject var docService = DocumentationService.shared
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var selectedAppID: UUID?

    @State private var analytics: [DocumentationAnalyticsEvent] = [
        DocumentationAnalyticsEvent(pageID: UUID(), timestamp: Date().addingTimeInterval(-3600), viewDuration: 42),
        DocumentationAnalyticsEvent(pageID: UUID(), timestamp: Date().addingTimeInterval(-7200), viewDuration: 120),
        DocumentationAnalyticsEvent(pageID: UUID(), timestamp: Date().addingTimeInterval(-86400), viewDuration: 15)
    ]

    var body: some View {
        List {
            Section("Documentation Engagement") {
                Picker("App", selection: $selectedAppID) {
                    Text("All Projects").tag(Optional<UUID>.none)
                    ForEach(appService.apps) { app in
                        Text(app.name).tag(Optional(app.id))
                    }
                }
            }

            Section("Performance Metrics") {
                HStack(spacing: 20) {
                    docMetric(label: "Avg Read Time", value: "2m 14s", color: .blue)
                    docMetric(label: "Exit Rate", value: "14%", color: .orange)
                    docMetric(label: "Helpful Score", value: "92%", color: .green)
                }
                .padding(.vertical, 8)
            }

            Section("Recent Page Interactions") {
                if analytics.isEmpty {
                    EmptyStateView(icon: "doc.text.magnifyingglass", title: "No Data", message: "Documentation analytics will appear here as developers interact with your content.")
                } else {
                    ForEach(analytics) { event in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Page View").font(.subheadline.bold())
                                Text(event.timestamp.formatted(date: .abbreviated, time: .shortened)).font(.system(size: 8)).foregroundStyle(.tertiary)
                            }
                            Spacer()
                            Text("\(Int(event.viewDuration))s duration").font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Docs Analytics")
        .onAppear {
            if selectedAppID == nil { selectedAppID = appService.apps.first?.id }
        }
    }

    private func docMetric(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 8, weight: .bold)).foregroundStyle(.secondary).textCase(.uppercase)
            Text(value).font(.subheadline.bold()).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
