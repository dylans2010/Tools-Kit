import SwiftUI

struct DocumentationAnalyticsView: View {
    @State private var analytics: [DocumentationAnalyticsEvent] = []

    var body: some View {
        List {
            Section("Documentation Performance") {
                if analytics.isEmpty {
                    Text("No analytics data available for your documentation pages.").foregroundStyle(.secondary)
                } else {
                    ForEach(analytics) { event in
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Page View").font(.subheadline.bold())
                                Text(event.timestamp.formatted()).font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(Int(event.viewDuration))s duration").font(.caption)
                        }
                    }
                }
            }
        }
        .navigationTitle("Docs Analytics")
    }
}
