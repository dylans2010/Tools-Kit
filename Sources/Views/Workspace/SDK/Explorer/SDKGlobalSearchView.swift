import SwiftUI

struct SDKGlobalSearchView: View {
    @StateObject private var projectManager = SDKProjectManager.shared
    @StateObject private var logStore = SDKLogStore.shared
    @State private var searchText = ""
    @State private var searchResults: [SearchResult] = []
    @State private var isSearching = false

    struct SearchResult: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let type: ResultType
        let destination: AnyView

        enum ResultType {
            case project, log, scope, tool, plugin
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar

            if isSearching {
                ProgressView()
                    .padding()
                Spacer()
            } else if searchText.isEmpty {
                EmptySearchPlaceholder()
            } else if searchResults.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                List {
                    ForEach(searchResults) { result in
                        NavigationLink(destination: result.destination) {
                            HStack(spacing: 12) {
                                Image(systemName: icon(for: result.type))
                                    .foregroundStyle(color(for: result.type))
                                    .frame(width: 32, height: 32)
                                    .background(color(for: result.type).opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(result.title)
                                        .font(.subheadline.bold())
                                    Text(result.subtitle)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Global Search")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: searchText) { _, _ in performSearch() }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search projects, logs, scopes, tools...", text: $searchText)
                .textFieldStyle(.plain)
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
        .padding()
    }

    private func performSearch() {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true

        let query = searchText.lowercased()
        var results: [SearchResult] = []

        // Projects
        for project in projectManager.projects where project.name.lowercased().contains(query) {
            results.append(SearchResult(
                title: project.name,
                subtitle: "SDK Project · \(project.status.rawValue.capitalized)",
                type: .project,
                destination: AnyView(SDKBuildView().onAppear { projectManager.loadProject(id: project.id) })
            ))
        }

        // Logs
        for entry in logStore.entries where entry.message.lowercased().contains(query) {
            results.append(SearchResult(
                title: entry.message,
                subtitle: "Log · \(entry.level.rawValue.capitalized) · \(entry.timestamp.formatted())",
                type: .log,
                destination: AnyView(SDKLogsView())
            ))
        }

        // Scopes
        for scope in SDKScope.allCases where scope.displayName.lowercased().contains(query) {
            let proj = projectManager.currentProject ?? (projectManager.projects.isEmpty ? nil : projectManager.projects[0])
            if let p = proj {
                results.append(SearchResult(
                    title: scope.displayName,
                    subtitle: "Permission Scope",
                    type: .scope,
                    destination: AnyView(SDKPermissionControlView(project: .constant(p)))
                ))
            }
        }

        searchResults = results
        isSearching = false
    }

    private func icon(for type: SearchResult.ResultType) -> String {
        switch type {
        case .project: return "cube.fill"
        case .log: return "doc.text.fill"
        case .scope: return "shield.fill"
        case .tool: return "hammer.fill"
        case .plugin: return "puzzlepiece.fill"
        }
    }

    private func color(for type: SearchResult.ResultType) -> Color {
        switch type {
        case .project: return .blue
        case .log: return .secondary
        case .scope: return .green
        case .tool: return .orange
        case .plugin: return .purple
        }
    }
}

private struct EmptySearchPlaceholder: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 64))
                .foregroundStyle(.tertiary)
            Text("Search the Workspace")
                .font(.headline)
            Text("Quickly find projects, logs, permissions, and tools across your entire SDK workspace.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxHeight: .infinity)
    }
}
