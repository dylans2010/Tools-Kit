import SwiftUI

struct WorkflowListView: View {
    let owner: String
    let repo: String

    @StateObject private var manager = WorkflowManager()
    @State private var searchText = ""
    @State private var selectedState = "all"

    private var filtered: [WorkflowSummary] {
        manager.summaries.filter { summary in
            let stateMatch = selectedState == "all" || summary.workflow.state == selectedState
            let searchMatch = searchText.isEmpty || summary.workflow.name.localizedCaseInsensitiveContains(searchText) || summary.workflow.path.localizedCaseInsensitiveContains(searchText)
            return stateMatch && searchMatch
        }
    }

    var body: some View {
        List {
            Section {
                LabeledContent("Total Workflows", value: "\(manager.summaries.count)")
                LabeledContent("Active", value: "\(manager.summaries.filter { $0.workflow.state == "active" }.count)")
                LabeledContent("Pinned", value: "\(manager.summaries.filter(\.isFavorite).count)")
                LabeledContent("Templates Available", value: "\(manager.templates.count)")
            } header: {
                Text("Dashboard")
            }

            Section {
                ForEach(filtered) { summary in
                    NavigationLink(destination: WorkflowDetailView(owner: owner, repo: repo, workflow: summary.workflow, lastRun: summary.lastRun)) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(summary.workflow.name).font(.headline)
                                if summary.isFavorite { Image(systemName: "pin.fill").foregroundStyle(.orange) }
                            }
                            Text(summary.workflow.path).font(.caption).foregroundStyle(.secondary)
                            Text("State: \(summary.workflow.state) • Trigger: \(summary.triggerDescription)").font(.caption2)
                            if let lastRun = summary.lastRun {
                                Text("Last run: #\(lastRun.runNumber) \(lastRun.status ?? "queued") / \(lastRun.conclusion ?? "-")")
                                    .font(.caption2)
                            }
                        }
                    }
                    .swipeActions {
                        Button {
                            manager.toggleFavorite(workflowID: summary.workflow.id)
                        } label: {
                            Label(summary.isFavorite ? "Unpin" : "Pin", systemImage: summary.isFavorite ? "pin.slash" : "pin")
                        }
                        .tint(.orange)
                    }
                }
            } header: {
                Text("Workflows")
            }
        }
        .overlay {
            if manager.isLoading { ProgressView("Loading Workflows...") }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu("Filter") {
                    Button("All") { selectedState = "all" }
                    Button("Active") { selectedState = "active" }
                    Button("Disabled") { selectedState = "disabled" }
                }
            }
        }
        .navigationTitle("Actions")
        .task { await manager.refresh(owner: owner, repo: repo) }
        .refreshable { await manager.refresh(owner: owner, repo: repo) }
    }
}
