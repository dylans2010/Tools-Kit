import SwiftUI

struct SDKDataInspectorView: View {
    let result: SDKFetchResult

    var body: some View {
        List {
            Section("Results (\(result.data.count))") {
                ForEach(result.data) { node in
                    VStack(alignment: .leading) {
                        Text(node.title).font(.headline)
                        Text(node.type.rawValue.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                        Text(node.content).font(.body).lineLimit(2).foregroundStyle(.secondary)
                    }
                }
            }

            if !result.relations.isEmpty {
                Section("Relations (\(result.relations.count))") {
                    ForEach(result.relations.indices, id: \.self) { index in
                        let rel = result.relations[index]
                        HStack {
                            Text(rel.sourceID.prefix(8))
                            Image(systemName: "arrow.right")
                            Text(rel.type)
                            Image(systemName: "arrow.right")
                            Text(rel.targetID.prefix(8))
                        }
                        .font(.caption)
                    }
                }
            }

            Section("Performance") {
                LabeledContent("Fetch Time", value: String(format: "%.3f s", result.performance.fetchTime))
                LabeledContent("Cache Hit", value: result.performance.cacheHit ? "Yes" : "No")
                LabeledContent("Parallel", value: result.performance.parallelExecution ? "Yes" : "No")
            }

            Section("Metadata") {
                LabeledContent("Total Count", value: "\(result.metadata.totalCount)")
                LabeledContent("Source Systems", value: result.metadata.sourceSystems.joined(separator: ", "))
            }
        }
        .navigationTitle("Data Inspector")
    }
}
