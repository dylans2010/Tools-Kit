import SwiftUI

struct MailSearchView: View {
    @ObservedObject var viewModel: MailViewModel
    @State private var searchText = ""
    @State private var results: [EmailMessage] = []

    var body: some View {
        NavigationStack {
            ZStack {
                Color.workspaceBackground.ignoresSafeArea()

                List {
                    if searchText.isEmpty {
                        emptySearchState
                    } else {
                        ForEach(results) { email in
                            NavigationLink(destination: MailThreadView(viewModel: viewModel, email: email)) {
                                searchResultRow(email: email)
                            }
                            .listRowBackground(Color.workspaceSurface)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Search")
            .searchable(text: $searchText, prompt: "Search people, subjects, or keywords")
            .onChange(of: searchText) { _, newValue in
                performSearch(newValue)
            }
        }
    }

    private var emptySearchState: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(.secondary.opacity(0.5))
            Text("Deep Semantic Search")
                .font(.headline)
            Text("Find anything across your connected accounts instantly.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 100)
        .listRowBackground(Color.clear)
    }

    private func searchResultRow(email: EmailMessage) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(email.sender).font(.subheadline.bold())
                Spacer()
                Text(email.date, style: .date).font(.caption2).foregroundStyle(.secondary)
            }
            Text(email.subject).font(.caption.bold())
            Text(email.preview).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
        }
        .padding(.vertical, 4)
    }

    private func performSearch(_ query: String) {
        guard !query.isEmpty else { results = []; return }
        results = viewModel.emails.filter {
            $0.subject.localizedCaseInsensitiveContains(query) ||
            $0.sender.localizedCaseInsensitiveContains(query)
        }
    }
}
