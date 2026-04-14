import SwiftUI

struct MailSearchView: View {
    let account: MailAccount
    @State private var searchText = ""
    @State private var results: [MailThread] = []

    var body: some View {
        List(results) { thread in
            NavigationLink(destination: MailThreadView(account: account, thread: thread)) {
                MailThreadRow(thread: thread)
            }
        }
        .navigationTitle("Search")
        .searchable(text: $searchText)
        .onChange(of: searchText) { newValue in
            performSearch(newValue)
        }
    }

    private func performSearch(_ query: String) {
        // Implement local search across all folders
    }
}
