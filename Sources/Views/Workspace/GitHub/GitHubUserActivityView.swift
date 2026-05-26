import SwiftUI

struct GitHubUserActivityView: View {
    let username: String
    @State private var events: [GitHubEvent] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading && events.isEmpty {
                ProgressView("Fetching Activity...")
            } else if events.isEmpty {
                ContentUnavailableView(
                    "No Recent Activity",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("We couldn't find any recent public events.")
                )
            } else {
                List(events) { event in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: iconFor(event.type))
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(formatMessage(for: event))
                                .font(.subheadline)

                            Text(event.repo.name)
                                .font(.caption.bold())
                                .foregroundStyle(.blue)

                            if let desc = event.payload?.description {
                                Text(desc)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }

                            Text(event.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.system(size: 10))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)
                .refreshable {
                    await fetchActivity()
                }
            }
        }
        .navigationTitle("Recent Activity")
        .task {
            await fetchActivity()
        }
        .alert("Error", isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Unknown Error")
        }
    }

    private func fetchActivity() async {
        isLoading = true
        do {
            let fetched: [GitHubEvent] = try await GitHubAPIClient.shared.request(.userEvents(username: username))
            await MainActor.run {
                self.events = fetched
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    private func iconFor(_ type: String) -> String {
        switch type {
        case "PushEvent": return "arrow.up.circle"
        case "PullRequestEvent": return "arrow.triangle.pull"
        case "IssuesEvent": return "exclamationmark.circle"
        case "WatchEvent": return "star"
        case "CreateEvent": return "plus.circle"
        case "ForkEvent": return "arrow.triangle.branch"
        case "ReleaseEvent": return "tag"
        default: return "bolt"
        }
    }

    private func formatMessage(for event: GitHubEvent) -> String {
        let actor = event.actor.login
        switch event.type {
        case "PushEvent":
            return "\(actor) pushed to \(event.payload?.ref?.replacingOccurrences(of: "refs/heads/", with: "") ?? "branch")"
        case "PullRequestEvent":
            return "\(actor) \(event.payload?.action ?? "opened") a pull request"
        case "IssuesEvent":
            return "\(actor) \(event.payload?.action ?? "opened") an issue"
        case "WatchEvent":
            return "\(actor) starred the repository"
        case "CreateEvent":
            return "\(actor) created \(event.payload?.refType ?? "resource")"
        case "ForkEvent":
            return "\(actor) forked the repository"
        default:
            return "\(actor) performed \(event.type.replacingOccurrences(of: "Event", with: ""))"
        }
    }
}
