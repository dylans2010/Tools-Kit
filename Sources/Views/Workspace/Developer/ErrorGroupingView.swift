import SwiftUI

struct ErrorGroupingView: View {
    @ObservedObject var analyticsService = AnalyticsService.shared
    @State private var errors: [String: Int] = [:]

    var body: some View {
        List {
            Section("Grouped Exceptions") {
                if errors.isEmpty {
                    Text("No errors reported in the last 24 hours.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(errors.sorted(by: { $0.value > $1.value }), id: \.key) { key, value in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(key).font(.subheadline.bold()).lineLimit(1)
                                Spacer()
                                Text("\(value) events").font(.system(size: 8, weight: .bold)).foregroundStyle(.red)
                            }
                            Text("Last seen 5m ago").font(.system(size: 8)).foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Error Grouping")
        .onAppear {
            Task {
                let report = try? await analyticsService.fetchErrorSummary(appID: nil, from: Date().addingTimeInterval(-86400), to: Date())
                await MainActor.run { self.errors = report ?? [:] }
            }
        }
    }
}
