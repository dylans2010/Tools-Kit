import SwiftUI

struct DocSectionEditor: View {
    @ObservedObject var docService = DocumentationService.shared
    @State private var sectionType: DocumentationSectionType = .guide

    var body: some View {
        List {
            Section("Document Sections") {
                ForEach(DocumentationSectionType.allCases, id: \.self) { type in
                    HStack {
                        Text(type.rawValue)
                        Spacer()
                        Text("\(docService.pages.filter { $0.sectionType == type }.count) pages")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Section Manager")
    }
}
