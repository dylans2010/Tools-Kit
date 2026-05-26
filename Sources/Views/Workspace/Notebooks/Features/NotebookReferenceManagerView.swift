import SwiftUI

struct NotebookReferenceManagerView: View {
    let content: String
    @State private var references: [Reference] = []
    @State private var searchText = ""
    @State private var selectedCategory: Reference.ReferenceType? = nil

    struct Reference: Identifiable {
        let id = UUID()
        let url: String
        let title: String
        let type: ReferenceType
        let dateAdded = Date()
        var importance: Importance = .medium
        var summary: String = ""

        enum ReferenceType: String, CaseIterable {
            case web = "Web"
            case file = "File"
            case citation = "Citation"
            case code = "Code"

            var icon: String {
                switch self {
                case .web: return "link"
                case .file: return "doc.fill"
                case .citation: return "quote.opening"
                case .code: return "chevron.left.forwardslash.chevron.right"
                }
            }
        }

        enum Importance: String, CaseIterable {
            case low = "Low", medium = "Medium", high = "High"
            var color: Color {
                switch self {
                case .low: return .gray
                case .medium: return .blue
                case .high: return .red
                }
            }
        }
    }

    var filteredReferences: [Reference] {
        references.filter { ref in
            let matchesSearch = searchText.isEmpty || ref.title.localizedCaseInsensitiveContains(searchText) || ref.url.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil || ref.type == selectedCategory
            return matchesSearch && matchesCategory
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            categoryPicker

            List {
                Section {
                    if filteredReferences.isEmpty {
                        ContentUnavailableView(
                            searchText.isEmpty ? "No References" : "No Results",
                            systemImage: "doc.text.magnifyingglass",
                            description: Text(searchText.isEmpty ? "No references found in this page." : "Try a different search term.")
                        )
                    } else {
                        ForEach(filteredReferences) { ref in
                            ReferenceRow(ref: ref)
                        }
                    }
                } header: {
                    Text("\(filteredReferences.count) References Found")
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle("Reference Manager")
        .searchable(text: $searchText, prompt: "Search references...")
        .onAppear(perform: extractReferences)
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryChip(nil, label: "All")
                ForEach(Reference.ReferenceType.allCases, id: \.self) { type in
                    categoryChip(type, label: type.rawValue)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(Color(.secondarySystemBackground))
    }

    private func categoryChip(_ type: Reference.ReferenceType?, label: String) -> some View {
        Button {
            withAnimation { selectedCategory = type }
        } label: {
            Text(label)
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedCategory == type ? Color.accentColor : Color(.tertiarySystemBackground), in: Capsule())
                .foregroundStyle(selectedCategory == type ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    private func extractReferences() {
        var found: [Reference] = []

        // Extract Markdown links [title](url)
        let regex = try? NSRegularExpression(pattern: "\\[(.*?)\\]\\((.*?)\\)", options: [])
        let nsString = content as NSString
        let results = regex?.matches(in: content, options: [], range: NSRange(location: 0, length: nsString.length))

        results?.forEach { match in
            if match.numberOfRanges >= 3 {
                let title = nsString.substring(with: match.range(at: 1))
                let url = nsString.substring(with: match.range(at: 2))

                let type: Reference.ReferenceType
                if url.hasPrefix("attachment://") {
                    type = .file
                } else if url.contains("github.com") || url.contains("gist.github.com") {
                    type = .code
                } else {
                    type = .web
                }

                var ref = Reference(url: url, title: title, type: type)
                if title.lowercased().contains("urgent") || title.lowercased().contains("important") {
                    ref.importance = .high
                }
                found.append(ref)
            }
        }

        // Extract raw URLs
        let urlRegex = try? NSRegularExpression(pattern: "(https?://[\\w\\-\\._~:/?#\\[\\]@!$&'()*+,;=%]+)", options: [])
        let urlResults = urlRegex?.matches(in: content, options: [], range: NSRange(location: 0, length: nsString.length))

        urlResults?.forEach { match in
            let url = nsString.substring(with: match.range)
            if !found.contains(where: { $0.url == url }) {
                found.append(Reference(url: url, title: "Web Link", type: .web))
            }
        }

        references = found
    }
}

private struct ReferenceRow: View {
    let ref: NotebookReferenceManagerView.Reference

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 32, height: 32)
                    Image(systemName: ref.type.icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.accentColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(ref.title)
                        .font(.subheadline.bold())
                    Text(ref.url)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if ref.type == .web || ref.type == .code, let url = URL(string: ref.url) {
                    Link(destination: url) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.title3)
                    }
                }
            }

            HStack {
                Text(ref.dateAdded, style: .date)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)

                Spacer()

                Text(ref.importance.rawValue)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(ref.importance.color.opacity(0.15), in: Capsule())
                    .foregroundStyle(ref.importance.color)
            }
        }
        .padding(.vertical, 4)
    }
}
