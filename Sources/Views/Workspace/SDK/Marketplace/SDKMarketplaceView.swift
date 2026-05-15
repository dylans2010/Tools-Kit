import SwiftUI

struct SDKMarketplaceView: View {
    @State private var extensions: [SDKExtension] = []
    @State private var searchText = ""
    @State private var selectedCategory: ExtCategory?

    fileprivate var filteredExtensions: [SDKExtension] {
        extensions.filter { ext in
            let matchesSearch = searchText.isEmpty || ext.name.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil || ext.category == selectedCategory
            return matchesSearch && matchesCategory
        }
    }

    var body: some View {
        List {
            Section("Featured") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(extensions.filter(\.isFeatured).prefix(3)) { ext in
                            featuredCard(ext)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        categoryChip(nil, label: "All")
                        ForEach(ExtCategory.allCases, id: \.self) { cat in
                            categoryChip(cat, label: cat.rawValue.capitalized)
                        }
                    }
                }
            }

            Section("Extensions (\(filteredExtensions.count))") {
                ForEach(filteredExtensions) { ext in
                    HStack(spacing: 12) {
                        Image(systemName: ext.icon)
                            .font(.title2)
                            .frame(width: 44, height: 44)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(ext.name).font(.subheadline.bold())
                                if ext.isVerified {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.caption)
                                        .foregroundStyle(.blue)
                                }
                            }
                            Text(ext.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                            HStack {
                                HStack(spacing: 2) {
                                    Image(systemName: "star.fill").foregroundStyle(.yellow)
                                    Text(String(format: "%.1f", ext.rating))
                                }
                                Text("(\(ext.reviewCount))")
                                Text(ext.author)
                            }
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button(ext.isInstalled ? "Installed" : "Get") {}
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(ext.isInstalled)
                    }
                }
            }
        }
        .navigationTitle("Marketplace")
        .searchable(text: $searchText, prompt: "Search extensions")
        .task { loadExtensions() }
    }

    private func featuredCard(_ ext: SDKExtension) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: ext.icon)
                .font(.largeTitle)
                .foregroundStyle(.blue)
            Text(ext.name).font(.headline)
            Text(ext.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(width: 180)
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func categoryChip(_ cat: ExtCategory?, label: String) -> some View {
        Button { selectedCategory = cat } label: {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(selectedCategory == cat ? Color.blue : Color(uiColor: .secondarySystemBackground))
                .foregroundStyle(selectedCategory == cat ? .white : .primary)
                .clipShape(Capsule())
        }
    }

    private func loadExtensions() {
        // Extensions are fetched from the marketplace registry; start empty until connected.
    }
}

private struct SDKExtension: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let category: ExtCategory
    let author: String
    let rating: Double
    let reviewCount: Int
    var isFeatured: Bool = false
    var isVerified: Bool = false
    var isInstalled: Bool = false
}

private enum ExtCategory: String, CaseIterable {
    case ai, themes, data, development, productivity
}
