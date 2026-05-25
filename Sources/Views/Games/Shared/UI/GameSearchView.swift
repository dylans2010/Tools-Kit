import SwiftUI

struct GameSearchView: View {
    @Binding var searchText: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.5))
            TextField("Search games...", text: $searchText)
                .foregroundColor(.white)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
    }

    static func filteredGames(searchText: String, category: GameCategory?) -> [GameDefinition] {
        var results = GameDefinition.allGames
        if let cat = category {
            results = results.filter { $0.category == cat }
        }
        if !searchText.isEmpty {
            let lower = searchText.lowercased()
            results = results.filter {
                $0.title.lowercased().contains(lower) ||
                $0.category.rawValue.lowercased().contains(lower)
            }
        }
        return results
    }
}
