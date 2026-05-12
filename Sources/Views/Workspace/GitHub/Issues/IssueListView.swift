import SwiftUI

struct IssueListView: View {
    let repository: GitHubRepository
    @State private var issues: [GitHubIssue] = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var filterState: IssueState = .open
    @State private var showingCreateSheet = false

    var filteredIssues: [GitHubIssue] {
        issues.filter { issue in
            let matchesState = issue.state == filterState
            let matchesSearch = searchText.isEmpty || issue.title.localizedCaseInsensitiveContains(searchText)
            return matchesState && matchesSearch
        }
    }

    var body: some View {
        Group {
            if isLoading && issues.isEmpty {
                ProgressView("Loading Issues...")
            } else {
                List {
                    Section {
                        Picker("State", selection: $filterState) {
                            Text("Open (\(issues.filter { $0.state == .open }.count))").tag(IssueState.open)
                            Text("Closed (\(issues.filter { $0.state == .closed }.count))").tag(IssueState.closed)
                        }
                        .pickerStyle(.segmented)
                    }

                    Section {
                        ForEach(filteredIssues) { issue in
                            NavigationLink(destination: IssueDetailView(issue: issue)) {
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: issue.state == .open ? "circle.circle" : "checkmark.circle.fill")
                                        .foregroundStyle(issue.state == .open ? .green : .purple)
                                        .padding(.top, 2)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(issue.title)
                                            .font(.subheadline.bold())
                                        HStack {
                                            Text("#\(issue.number)")
                                            Text("opened \(issue.createdAt.formatted(date: .abbreviated, time: .omitted))")
                                        }
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        if !issue.labels.isEmpty {
                                            HStack(spacing: 4) {
                                                ForEach(issue.labels, id: \.self) { label in
                                                    Text(label)
                                                        .font(.caption2)
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(Color.blue.opacity(0.15))
                                                        .clipShape(Capsule())
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .refreshable { await loadIssues() }
            }
        }
        .navigationTitle("Issues")
        .searchable(text: $searchText, prompt: "Search issues")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingCreateSheet = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            NavigationStack { CreateIssueView(repository: repository) }
        }
        .task { await loadIssues() }
    }

    private func loadIssues() async {
        isLoading = true
        // Issues are fetched from the GitHub API; start empty until connected to a repository.
        issues = []
        isLoading = false
    }
}

struct GitHubIssue: Identifiable, Sendable {
    let id = UUID()
    let number: Int
    let title: String
    let state: IssueState
    let labels: [String]
    let createdAt: Date
    var body: String = ""
    var assignee: String? = nil
    var commentCount: Int = 0
}

enum IssueState: String, Codable, Sendable { case open, closed }
