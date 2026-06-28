#if canImport(ScreenCaptureKit)

import SwiftUI


@available(iOS 27.0, *)
struct SCKAnalyticsView: View {
    @State private var recordings: [SCKRecordingSession] = []

    var body: some View {
        List {
            Section("Overview") {
                HStack {
                    LabeledContent("Total Recordings", value: "\(recordings.count)")
                    Spacer()
                    LabeledContent("Total Duration", value: formatTotalDuration())
                }
            }

            Section("Feature Usage") {
                ForEach(SCKFeatureType.allCases, id: \.self) { type in
                    let count = recordings.filter { $0.featureType == type }.count
                    HStack {
                        Text(type.rawValue)
                        Spacer()
                        Text("\(count)")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Recent Insights") {
                if recordings.isEmpty {
                    Text("No data available yet.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(recordings.prefix(5)) { session in
                        VStack(alignment: .leading) {
                            Text(session.title)
                                .font(.subheadline.bold())
                            Text("\(session.transcript.count) transcript segments • \(session.ocrResults.count) OCR results")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Analytics")
        .onAppear {
            recordings = RecordingStorageManager.shared.loadSessions()
        }
    }

    private func formatTotalDuration() -> String {
        let total = recordings.reduce(0) { $0 + $1.duration }
        let hours = Int(total) / 3600
        let mins = (Int(total) % 3600) / 60
        return "\(hours)h \(mins)m"
    }
}


#endif
