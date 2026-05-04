import SwiftUI

struct GitHubHotspotDetectorView: View {
    @ObservedObject private var analyzer = RepoAnalyzerService.shared
    @ObservedObject private var gitEngine = GitEngineService.shared

    var body: some View {
        List {
            Section("High Churn Files") {
                if analyzer.hotspots.isEmpty {
                    Text("No hotspot data. Analyze commits first.")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(analyzer.hotspots) { hotspot in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(URL(fileURLWithPath: hotspot.filePath).lastPathComponent).font(.subheadline.bold())
                                Spacer()
                                Text("\(hotspot.churn) commits").font(.caption2).foregroundStyle(.secondary)
                            }

                            HStack {
                                Text("Instability Score").font(.caption2)
                                Spacer()
                                Text(String(format: "%.1f", hotspot.instability)).font(.caption2.bold())
                                    .foregroundColor(hotspot.instability > 0.7 ? .red : .orange)
                            }

                            ProgressView(value: hotspot.instability)
                                .tint(hotspot.instability > 0.7 ? .red : .orange)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section {
                Button("Run Churn Analysis") {
                    analyzer.analyze(commits: gitEngine.localCommits)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Hotspot Detector")
    }
}
