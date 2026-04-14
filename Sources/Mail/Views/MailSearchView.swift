import SwiftUI

struct MailSearchView: View {
    @ObservedObject var viewModel: MailViewModel
    @State private var searchText = ""
    @State private var results: [EmailMessage] = []

    var body: some View {
        List(results) { email in
            NavigationLink(destination: MailThreadView(viewModel: viewModel, email: email)) {
                VStack(alignment: .leading, spacing: 4) {
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
                        .font(.subheadline)
                        .lineLimit(1)
                    if !email.preview.isEmpty {
                        Text(email.preview)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
            }
        }
        .navigationTitle("Search")
        .searchable(text: $searchText)
        .onChange(of: searchText) { newValue in
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
