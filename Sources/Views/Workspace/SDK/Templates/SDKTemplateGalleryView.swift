import SwiftUI

struct SDKTemplateGalleryView: View {
    @StateObject private var templateManager = AISlidesTemplateManager.shared
    @State private var searchText = ""
    @State private var selectedCategory: TemplateCategory?

    var filteredTemplates: [SlideTemplate] {
        let searched = searchText.isEmpty ? templateManager.templates : templateManager.search(searchText)
        if let cat = selectedCategory {
            return searched.filter { $0.category == cat }
        }
        return searched
    }

    var body: some View {
        List {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        categoryChip(nil, label: "All")
                        ForEach(TemplateCategory.allCases, id: \.self) { cat in
                            categoryChip(cat, label: cat.displayName)
                        }
                    }
                }
            }

            if !templateManager.favorites().isEmpty {
                Section("Favorites") {
                    ForEach(templateManager.favorites()) { template in
                        templateRow(template)
                    }
                }
            }

            Section("All Templates (\(filteredTemplates.count))") {
                ForEach(filteredTemplates) { template in
                    templateRow(template)
                }
            }
        }
        .navigationTitle("Template Gallery")
        .searchable(text: $searchText, prompt: "Search templates")
    }

    private func templateRow(_ template: SlideTemplate) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: template.category.icon)
                    .font(.title2)
                    .frame(width: 36, height: 36)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading) {
                    Text(template.name).font(.headline)
                    Text(template.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                Button {
                    templateManager.toggleFavorite(id: template.id)
                } label: {
                    Image(systemName: templateManager.isFavorite(id: template.id) ? "star.fill" : "star")
                        .foregroundStyle(.yellow)
                }
            }
            HStack {
                Text("\(template.slideLayouts.count) slides")
                if !template.tags.isEmpty {
                    ForEach(template.tags.prefix(3), id: \.self) { tag in
                        Text(tag)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(Capsule())
                    }
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private func categoryChip(_ category: TemplateCategory?, label: String) -> some View {
        Button { selectedCategory = category } label: {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(selectedCategory == category ? Color.blue : Color(.secondarySystemBackground))
                .foregroundStyle(selectedCategory == category ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}
