import SwiftUI

struct BatchProcessingView: View {
    @StateObject private var manager = BatchProcessingManager.shared

    var body: some View {
        List {
            Section(header: Text("Active Jobs")) {
                if manager.activeJobs.isEmpty {
                    Text("No active batch jobs.")
                        .foregroundColor(.secondary)
                }

                ForEach(manager.activeJobs) { job in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Processing \(job.projectIDs.count) Projects").bold()
                            Spacer()
                            Text(job.status.rawValue.capitalized)
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(4)
                        }

                        ProgressView(value: job.progress)

                        Text(job.operations.map { $0.rawValue }.joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section {
                Button("Start New Batch Export") {
                    manager.startBatchJob(projectIDs: [UUID(), UUID()], operations: [.exportHighRes, .optimizeForWeb])
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Batch Processing")
    }
}
