import SwiftUI

struct MailSearchView: View {
    @ObservedObject var viewModel: MailViewModel
    @State private var searchText = ""
    @State private var results: [EmailMessage] = []

    var body: some View {
        List {
            if searchText.isEmpty {
                Section {
                    VStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Text("Search your mail")
                            .font(.headline)
                        Text("Find messages by sender or subject.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .listRowBackground(Color.clear)
                }
            } else if results.isEmpty {
                Section {
                    Text("No results for \"\(searchText)\"")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 16)
                        .listRowBackground(Color.clear)
                }
            } else {
                ForEach(results) { email in
                    NavigationLink(destination: MailThreadView(viewModel: viewModel, email: email)) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(email.sender)
                                    .font(.headline)
                                    .lineLimit(1)
                                Spacer()
                                Text(email.date, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Text(email.subject)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                            if !email.preview.isEmpty {
                                Text(email.preview)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemBackground))
                        )
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                    .listRowBackground(Color.clear)
                }
            }
        }
        .navigationTitle("Search")
        .listStyle(.insetGrouped)
        .searchable(text: $searchText)
        .onChange(of: searchText) { _, newValue in
            performSearch(newValue)
        }
    }

    private func performSearch(_ query: String) {
        guard !query.isEmpty else { results = []; return }
        results = viewModel.emails.filter {
            $0.subject.localizedCaseInsensitiveContains(query) ||
            $0.sender.localizedCaseInsensitiveContains(query)
        }
    }
}
