import SwiftUI

struct DocSectionEditor: View {
    @ObservedObject var docService = DocumentationService.shared
    @State private var showingEditType = false
    @State private var selectedPage: DocumentationPage?

    var body: some View {
        List {
            Section("Section Taxonomies") {
                Text("Manage how your documentation is categorized for developers. Changes affect sidebar organization in the public docs portal.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            ForEach(DocumentationSectionType.allCases, id: \.self) { type in
                Section(type.rawValue.uppercased()) {
                    let pages = docService.pages.filter { $0.sectionType == type }
                    if pages.isEmpty {
                        Text("No pages in this section.").font(.caption).foregroundStyle(.tertiary)
                    } else {
                        ForEach(pages) { page in
                            HStack {
                                Text(page.title).font(.subheadline.bold())
                                Spacer()
                                Button {
                                    selectedPage = page
                                    showingEditType = true
                                } label: {
                                    Image(systemName: "folder.badge.gearshape").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Doc Sections")
        .sheet(item: $selectedPage) { page in
            SectionMoveSheet(page: page)
        }
    }
}

struct SectionMoveSheet: View {
    let page: DocumentationPage
    @Environment(\.dismiss) var dismiss
    @ObservedObject var docService = DocumentationService.shared
    @State private var selectedType: DocumentationSectionType = .guide

    var body: some View {
        NavigationStack {
            Form {
                Section("Update Category") {
                    Text("Current: \(page.sectionType.rawValue)").font(.caption).foregroundStyle(.secondary)
                    Picker("New Section", selection: $selectedType) {
                        ForEach(DocumentationSectionType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.inline)
                }
            }
            .navigationTitle("Move Page")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Update") {
                        var updated = page
                        updated.sectionType = selectedType
                        Task {
                            try? await docService.savePage(updated)
                            await MainActor.run { dismiss() }
                        }
                    }
                }
            }
            .onAppear { selectedType = page.sectionType }
        }
    }
}
