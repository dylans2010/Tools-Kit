
import SwiftUI

struct SDKGlobalSearchView: View {
    @State private var query = ""
    @State private var results: [SearchResult] = []

    struct SearchResult: Identifiable {
        let id = UUID()
        let title: String
        let type: String
    }

    var body: some View {
        VStack {
            TextField("Search in SDK components...", text: $query)
                .textFieldStyle(.roundedBorder)
                .padding()

            List(results) { result in
                HStack {
                    VStack(alignment: .leading) {
                        Text(result.title).bold()
                        Text(result.type).font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }

            if results.isEmpty && !query.isEmpty {
                ContentUnavailableView.search(text: query)
            }
        }
        .navigationTitle("Global Search")
    }
}
