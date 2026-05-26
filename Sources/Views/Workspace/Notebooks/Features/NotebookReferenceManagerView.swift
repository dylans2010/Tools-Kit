import SwiftUI

struct NotebookReferenceManagerView: View {
    let content: String
    @State private var references: [Reference] = []

    struct Reference: Identifiable {
        let id = UUID()
        let url: String
        let title: String
        let type: ReferenceType

        enum ReferenceType {
            case web, file, citation
            var icon: String {
                switch self {
                case .web: return "link"
                case .file: return "doc.fill"
                case .citation: return "quote.opening"
                }
            }
        }
    }

    var body: some View {
        List {
            Section("Links & Attachments") {
                if references.isEmpty {
                    Text("No references found in this page.").foregroundStyle(.secondary).font(.caption)
                } else {
                    ForEach(references) { ref in
                        HStack(spacing: 12) {
                            Image(systemName: ref.type.icon)
                                .foregroundStyle(.blue)
                                .frame(width: 30)
                            VStack(alignment: .leading) {
                                Text(ref.title).font(.subheadline.bold())
                                Text(ref.url).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                            }
                            Spacer()
                            if ref.type == .web, let url = URL(string: ref.url) {
                                Link(destination: url) {
                                    Image(systemName: "arrow.up.right.square")
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Reference Manager")
        .onAppear(perform: extractReferences)
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

                let type: Reference.ReferenceType = url.hasPrefix("attachment://") ? .file : .web
                found.append(Reference(url: url, title: title, type: type))
            }
        }

        references = found
    }
}
