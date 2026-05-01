import SwiftUI

/// View for exploring relationships and context in a graph format.
struct MemoryGraphViewer: View {
    @State private var nodes: [MemoryGraphNode] = []
    @State private var isLoading = false

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Mapping context...")
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(nodes) { node in
                            WorkspaceSurfaceCard {
                                HStack {
                                    Image(systemImage: icon(for: node.type))
                                        .foregroundStyle(.purple)
                                    VStack(alignment: .leading) {
                                        Text(node.value)
                                            .font(.subheadline.bold())
                                        Text(node.type.rawValue.capitalized)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(node.timestamp, style: .date)
                                        .font(.caption2)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Memory Graph")
        .onAppear(perform: loadGraph)
    }

    private func icon(for type: MemoryGraphNode.NodeType) -> String {
        switch type {
        case .person: return "person.circle"
        case .organization: return "building.2"
        case .topic: return "tag"
        case .decision: return "checkmark.seal"
        case .commitment: return "hand.point.right"
        }
    }

    private func loadGraph() {
        isLoading = true
        Task {
            nodes = await MemoryGraphEngine.shared.recallContext(for: "")
            isLoading = false
        }
    }
}

/// Panel for displaying parsed file data and OCR results.
struct AttachmentIntelligencePanel: View {
    let attachment: MailMessage.MailAttachment
    @State private var intelligence: AttachmentIntelligence?
    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Attachment Intel", systemImage: "doc.text.magnifyingglass")
                .font(.headline)

            if isLoading {
                ProgressView()
            } else if let intel = intelligence {
                VStack(alignment: .leading, spacing: 8) {
                    Text(intel.fileName)
                        .font(.subheadline.bold())
                    Text(intel.fileType.rawValue.capitalized)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let summary = intel.summary {
                        Text("Summary")
                            .font(.caption.bold())
                        Text(summary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let data = intel.extractedData, !data.isEmpty {
                        Divider()
                        ForEach(Array(data.keys), id: \.self) { key in
                            HStack {
                                Text(key).font(.caption.bold())
                                Spacer()
                                Text(data[key] ?? "").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
        .onAppear(perform: analyze)
    }

    private func analyze() {
        isLoading = true
        Task {
            // Fetch real attachment data from MailStorageService
            let data = MailStorageService.shared.loadAttachmentData(attachmentID: attachment.id) ?? Data()
            intelligence = try? await AttachmentIntelligenceEngine.shared.analyzeAttachment(attachment, content: data)
            isLoading = false
        }
    }
}

/// Viewer for merged conversation context across related threads.
struct MultiThreadContextViewer: View {
    let threadIDs: [String]
    @State private var threads: [MailThread] = []
    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading) {
            Text("Merged Thread Context")
                .font(.headline)
                .padding(.horizontal)

            if isLoading {
                ProgressView().padding()
            } else {
                List(threads) { thread in
                    VStack(alignment: .leading) {
                        Text(thread.subject).font(.subheadline.bold())
                        Text(thread.snippet).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
                .listStyle(.plain)
                .frame(height: 200)
            }
        }
        .onAppear(perform: load)
    }

    private func load() {
        isLoading = true
        Task {
            let allThreads = MailStorageService.shared.loadThreads(for: "all")
            let relatedGroups = try? await MultiThreadCorrelationEngine.shared.correlateThreads(threads: allThreads)

            if let group = relatedGroups?.first(where: { $0.contains(where: { threadIDs.contains($0) }) }) {
                self.threads = allThreads.filter { group.contains($0.id) }
            }
            isLoading = false
        }
    }
}
