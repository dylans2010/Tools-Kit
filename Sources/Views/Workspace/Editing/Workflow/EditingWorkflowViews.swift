import SwiftUI

struct AssetManagerView: View {
    @StateObject private var manager = AssetManager.shared

    var body: some View {
        List {
            ForEach(manager.assets) { asset in
                HStack {
                    VStack(alignment: .leading) {
                        Text(asset.name)
                            .font(.headline)
                        HStack {
                            ForEach(asset.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    Spacer()
                    Image(systemName: "photo")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Asset Library")
    }
}

struct ExportQueueView: View {
    @StateObject private var manager = ExportPipelineManager.shared

    var body: some View {
        List {
            ForEach(manager.activeJobs) { job in
                VStack(alignment: .leading) {
                    HStack {
                        Text(job.projectName)
                            .font(.headline)
                        Spacer()
                        Text(job.status)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }

                    ProgressView(value: job.progress)
                        .accentColor(.blue)
                }
                .padding(.vertical, 4)
            }

            if manager.activeJobs.isEmpty {
                Text("No Active Exports")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Export Queue")
    }
}
