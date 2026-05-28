import SwiftUI

// MARK: - Models

enum CitationSourceType: String, CaseIterable, Identifiable {
    case book = "Book"
    case journalArticle = "Journal Article"
    case website = "Website"
    case conferenceProceeding = "Conference"
    case thesis = "Thesis/Dissertation"
    case film = "Film/Video"
    case podcast = "Podcast"
    case socialMedia = "Social Media"
    case governmentDoc = "Government Document"
    case patent = "Patent"
    case interview = "Interview"
    case software = "Software"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .book: return "book.closed"
        case .journalArticle: return "doc.text"
        case .website: return "globe"
        case .conferenceProceeding: return "person.3"
        case .thesis: return "graduationcap"
        case .film: return "film"
        case .podcast: return "mic"
        case .socialMedia: return "at"
        case .governmentDoc: return "building.columns"
        case .patent: return "scroll"
        case .interview: return "bubble.left.and.bubble.right"
        case .software: return "desktopcomputer"
        }
    }
}

enum CitationFormatStyle: String, CaseIterable, Identifiable {
    case apa7 = "APA 7th"
    case mla9 = "MLA 9th"
    case chicagoAD = "Chicago (Author-Date)"
    case chicagoNB = "Chicago (Notes-Bib)"
    case harvard = "Harvard"
    case ieee = "IEEE"
    case vancouver = "Vancouver"
    case acs = "ACS"
    case ama = "AMA"
    case asa = "ASA"
    case bluebook = "Bluebook"
    case oscola = "OSCOLA"
    case turabian = "Turabian"
    case cse = "CSE"
    case nlm = "NLM"
    case nature = "Nature"
    var id: String { rawValue }
}

struct CitationField: Identifiable {
    let id = UUID()
    let label: String
    let placeholder: String
    let icon: String
    var isRequired: Bool = false
}

struct GeneratedCitation: Identifiable {
    let id = UUID()
    let style: String
    let formatted: String
    let inText: String
}

// MARK: - ViewModel

class CitationFormatsViewModel: ObservableObject {
    @Published var selectedSourceType: CitationSourceType = .book
    @Published var selectedStyles: Set<String> = ["APA 7th", "MLA 9th"]
    @Published var searchText = ""
    @Published var selectedTab: CitationTab = .templates
    @Published var showGenerator = false

    // Generator fields
    @Published var authorFirst = ""
    @Published var authorLast = ""
    @Published var additionalAuthors: [String] = []
    @Published var title = ""
    @Published var year = ""
    @Published var publisher = ""
    @Published var journalName = ""
    @Published var volume = ""
    @Published var issue = ""
    @Published var pages = ""
    @Published var doi = ""
    @Published var url = ""
    @Published var accessDate = ""
    @Published var edition = ""
    @Published var city = ""
    @Published var editor = ""
    @Published var chapterTitle = ""

    @Published var generatedCitations: [GeneratedCitation] = []
    @Published var isGenerating = false
    @Published var savedCitations: [GeneratedCitation] = []
    @Published var recentFormats: [String] = []
    @Published var annotationNotes: [String: String] = [:]
    @Published var citationGroups: [CitationGroup] = []
    @Published var exportFormat: ExportFormat = .plainText
    @Published var showBatchExport = false
    @Published var sortOrder: SortOrder = .dateAdded
    @Published var duplicateWarnings: [String] = []

    enum CitationTab: String, CaseIterable {
        case templates = "Templates"
        case generator = "Generator"
        case saved = "Saved"
        case bibliography = "Bibliography"
    }

    enum ExportFormat: String, CaseIterable {
        case plainText = "Plain Text"
        case richText = "Rich Text"
        case bibtex = "BibTeX"
        case ris = "RIS"
        case endnote = "EndNote XML"
    }

    enum SortOrder: String, CaseIterable {
        case dateAdded = "Date Added"
        case authorAZ = "Author A-Z"
        case yearDesc = "Year (Newest)"
        case yearAsc = "Year (Oldest)"
        case styleGroup = "Style"
    }

    var fieldsForSourceType: [CitationField] {
        var fields: [CitationField] = [
            CitationField(label: "Last Name", placeholder: "Smith", icon: "person", isRequired: true),
            CitationField(label: "First Name", placeholder: "John", icon: "person", isRequired: true),
            CitationField(label: "Title", placeholder: "The Future of AI", icon: "text.quote", isRequired: true),
            CitationField(label: "Year", placeholder: "2024", icon: "calendar", isRequired: true)
        ]
        switch selectedSourceType {
        case .book:
            fields += [
                CitationField(label: "Publisher", placeholder: "Tech Press", icon: "building.2"),
                CitationField(label: "City", placeholder: "San Francisco", icon: "mappin"),
                CitationField(label: "Edition", placeholder: "2nd", icon: "number"),
                CitationField(label: "Editor", placeholder: "B. Doe", icon: "person.2"),
                CitationField(label: "Chapter Title", placeholder: "AI Ethics", icon: "bookmark"),
                CitationField(label: "DOI", placeholder: "10.1234/5678", icon: "link")
            ]
        case .journalArticle:
            fields += [
                CitationField(label: "Journal", placeholder: "Journal of Technology", icon: "newspaper"),
                CitationField(label: "Volume", placeholder: "12", icon: "number"),
                CitationField(label: "Issue", placeholder: "3", icon: "number"),
                CitationField(label: "Pages", placeholder: "45-67", icon: "doc.plaintext"),
                CitationField(label: "DOI", placeholder: "10.1234/5678", icon: "link")
            ]
        case .website:
            fields += [
                CitationField(label: "URL", placeholder: "https://example.com", icon: "globe", isRequired: true),
                CitationField(label: "Access Date", placeholder: "20 May 2024", icon: "calendar.badge.clock"),
                CitationField(label: "Publisher/Site", placeholder: "Tech Today", icon: "building.2")
            ]
        case .conferenceProceeding:
            fields += [
                CitationField(label: "Conference Name", placeholder: "AI World 2024", icon: "person.3"),
                CitationField(label: "City", placeholder: "San Francisco", icon: "mappin"),
                CitationField(label: "Pages", placeholder: "45-67", icon: "doc.plaintext"),
                CitationField(label: "DOI", placeholder: "10.1234/5678", icon: "link")
            ]
        case .thesis:
            fields += [
                CitationField(label: "University", placeholder: "Tech University", icon: "graduationcap"),
                CitationField(label: "Degree Type", placeholder: "Doctoral dissertation", icon: "scroll"),
                CitationField(label: "Database", placeholder: "ProQuest", icon: "externaldrive")
            ]
        case .film:
            fields += [
                CitationField(label: "Studio", placeholder: "AI Studios", icon: "film"),
                CitationField(label: "Role", placeholder: "Director", icon: "person.crop.rectangle"),
                CitationField(label: "URL", placeholder: "https://example.com", icon: "globe")
            ]
        case .podcast:
            fields += [
                CitationField(label: "Podcast Name", placeholder: "Tech Talk", icon: "mic"),
                CitationField(label: "Episode Number", placeholder: "42", icon: "number"),
                CitationField(label: "Network", placeholder: "AI Network", icon: "antenna.radiowaves.left.and.right"),
                CitationField(label: "URL", placeholder: "https://techtalk.fm/42", icon: "globe")
            ]
        case .socialMedia:
            fields += [
                CitationField(label: "Platform", placeholder: "X (Twitter)", icon: "at"),
                CitationField(label: "Handle", placeholder: "@jsmith", icon: "person.circle"),
                CitationField(label: "Post Date", placeholder: "20 May 2024", icon: "calendar"),
                CitationField(label: "URL", placeholder: "https://x.com/...", icon: "globe")
            ]
        case .governmentDoc:
            fields += [
                CitationField(label: "Agency", placeholder: "National AI Agency", icon: "building.columns"),
                CitationField(label: "Report No.", placeholder: "123", icon: "number"),
                CitationField(label: "URL", placeholder: "https://agency.gov/doc", icon: "globe")
            ]
        case .patent:
            fields += [
                CitationField(label: "Patent Number", placeholder: "1,234,567", icon: "number"),
                CitationField(label: "Country", placeholder: "U.S.", icon: "flag"),
                CitationField(label: "Office", placeholder: "Patent and Trademark Office", icon: "building.columns")
            ]
        case .interview:
            fields += [
                CitationField(label: "Interview Type", placeholder: "Personal interview", icon: "bubble.left.and.bubble.right"),
                CitationField(label: "Date", placeholder: "20 May 2024", icon: "calendar")
            ]
        case .software:
            fields += [
                CitationField(label: "Version", placeholder: "1.0", icon: "number"),
                CitationField(label: "Platform", placeholder: "App Store", icon: "desktopcomputer"),
                CitationField(label: "URL", placeholder: "https://example.com", icon: "globe")
            ]
        }
        return fields
    }

    func generateCitations() {
        guard !title.isEmpty, !authorLast.isEmpty else { return }
        isGenerating = true
        generatedCitations = []

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
            var results: [GeneratedCitation] = []
            let authorFull = authorFirst.isEmpty ? authorLast : "\(authorLast), \(authorFirst.prefix(1))."
            let authorFullName = authorFirst.isEmpty ? authorLast : "\(authorLast), \(authorFirst)"
            let yr = year.isEmpty ? "n.d." : year

            for styleName in selectedStyles {
                let formatted: String
                let inText: String

                switch styleName {
                case "APA 7th":
                    if selectedSourceType == .journalArticle {
                        formatted = "\(authorFull) (\(yr)). \(title). *\(journalName.isEmpty ? "Journal Name" : journalName)*, *\(volume)*(\(issue)), \(pages).\(doi.isEmpty ? "" : " https://doi.org/\(doi)")"
                    } else if selectedSourceType == .website {
                        formatted = "\(authorFull) (\(yr)). *\(title)*. \(publisher.isEmpty ? "" : "\(publisher). ")\(url)"
                    } else {
                        formatted = "\(authorFull) (\(yr)). *\(title)*.\(publisher.isEmpty ? "" : " \(publisher).")\(doi.isEmpty ? "" : " https://doi.org/\(doi)")"
                    }
                    inText = "(\(authorLast), \(yr))"

                case "MLA 9th":
                    if selectedSourceType == .journalArticle {
                        formatted = "\(authorFullName). \"\(title).\" *\(journalName.isEmpty ? "Journal Name" : journalName)*, vol. \(volume), no. \(issue), \(yr), pp. \(pages)."
                    } else if selectedSourceType == .website {
                        formatted = "\(authorFullName). \"\(title).\" *\(publisher.isEmpty ? "Site Name" : publisher)*, \(yr), \(url)."
                    } else {
                        formatted = "\(authorFullName). *\(title)*.\(publisher.isEmpty ? "" : " \(publisher),") \(yr)."
                    }
                    inText = "(\(authorLast) \(pages.isEmpty ? "" : pages))"

                case "Chicago (Author-Date)":
                    formatted = "\(authorFullName). \(yr). *\(title)*.\(city.isEmpty ? "" : " \(city):") \(publisher.isEmpty ? "" : "\(publisher).")"
                    inText = "(\(authorLast) \(yr))"

                case "Chicago (Notes-Bib)":
                    formatted = "\(authorFullName). *\(title)*.\(city.isEmpty ? "" : " \(city):") \(publisher.isEmpty ? "" : "\(publisher),") \(yr)."
                    inText = "\(authorFullName), *\(title)* (\(city.isEmpty ? "" : "\(city): ")\(publisher.isEmpty ? "Publisher" : publisher), \(yr)), \(pages.isEmpty ? "1" : pages)."

                case "Harvard":
                    formatted = "\(authorFull) (\(yr)) *\(title)*.\(city.isEmpty ? "" : " \(city):") \(publisher.isEmpty ? "" : "\(publisher).")"
                    inText = "(\(authorLast) \(yr))"

                case "IEEE":
                    formatted = "[1] \(authorFirst.prefix(1)). \(authorLast), \"\(title),\" *\(journalName.isEmpty ? "Publication" : journalName)*, vol. \(volume), no. \(issue), pp. \(pages), \(yr)."
                    inText = "[1]"

                case "Vancouver":
                    formatted = "\(authorLast) \(authorFirst.prefix(1)). \(title). \(journalName.isEmpty ? "Journal" : journalName). \(yr);\(volume)(\(issue)):\(pages).\(doi.isEmpty ? "" : " doi:\(doi)")"
                    inText = "(1)"

                case "ACS":
                    formatted = "\(authorFull) *\(journalName.isEmpty ? "J. Name" : journalName)* **\(yr)**, *\(volume)*, \(pages)."
                    inText = "(\(Int(yr) ?? 1))"

                case "AMA":
                    formatted = "\(authorLast) \(authorFirst.prefix(1)). \(title). *\(journalName.isEmpty ? "Journal" : journalName)*. \(yr);\(volume)(\(issue)):\(pages).\(doi.isEmpty ? "" : " doi:\(doi)")"
                    inText = "¹"

                case "ASA":
                    formatted = "\(authorFullName). \(yr). \"\(title).\" *\(journalName.isEmpty ? "Journal" : journalName)* \(volume)(\(issue)):\(pages)."
                    inText = "(\(authorLast) \(yr))"

                case "Bluebook":
                    formatted = "\(authorFullName), *\(title)*, \(volume) \(journalName.isEmpty ? "J." : journalName) \(pages) (\(yr))."
                    inText = "\(authorLast), supra note 1"

                case "OSCOLA":
                    formatted = "\(authorFullName), *\(title)* (\(publisher.isEmpty ? "Publisher" : publisher) \(yr)) \(pages)."
                    inText = "\(authorLast) (n 1)"

                case "Turabian":
                    formatted = "\(authorFullName). *\(title)*.\(city.isEmpty ? "" : " \(city):") \(publisher.isEmpty ? "" : "\(publisher),") \(yr)."
                    inText = "(\(authorLast) \(yr), \(pages.isEmpty ? "1" : pages))"

                case "CSE":
                    formatted = "\(authorLast) \(authorFirst.prefix(1)). \(yr). \(title). \(journalName.isEmpty ? "Journal" : journalName). \(volume):\(pages)."
                    inText = "(\(authorLast) \(yr))"

                case "NLM":
                    formatted = "\(authorLast) \(authorFirst.prefix(1)). \(title). \(journalName.isEmpty ? "Journal" : journalName). \(yr);\(volume)(\(issue)):\(pages)."
                    inText = "(\(Int(yr) ?? 1))"

                case "Nature":
                    formatted = "\(authorFull) \(title). *\(journalName.isEmpty ? "Nature" : journalName)* \(volume), \(pages) (\(yr)).\(doi.isEmpty ? "" : " https://doi.org/\(doi)")"
                    inText = "¹"

                default:
                    formatted = "\(authorFull) (\(yr)). *\(title)*."
                    inText = "(\(authorLast), \(yr))"
                }

                results.append(GeneratedCitation(style: styleName, formatted: formatted, inText: inText))
            }

            self.generatedCitations = results
            self.isGenerating = false

            if !self.recentFormats.contains(self.title) && !self.title.isEmpty {
                self.recentFormats.insert(self.title, at: 0)
                if self.recentFormats.count > 10 { self.recentFormats.removeLast() }
            }
        }
    }

    func saveCitation(_ citation: GeneratedCitation) {
        if !savedCitations.contains(where: { $0.formatted == citation.formatted }) {
            savedCitations.insert(citation, at: 0)
        }
    }

    func clearFields() {
        authorFirst = ""
        authorLast = ""
        additionalAuthors = []
        title = ""
        year = ""
        publisher = ""
        journalName = ""
        volume = ""
        issue = ""
        pages = ""
        doi = ""
        url = ""
        accessDate = ""
        edition = ""
        city = ""
        editor = ""
        chapterTitle = ""
        generatedCitations = []
    }

    func exportAllSaved() -> String {
        switch exportFormat {
        case .plainText:
            return savedCitations.map { "[\($0.style)] \($0.formatted)" }.joined(separator: "\n\n")
        case .richText:
            return savedCitations.map { "**\($0.style)**\n\($0.formatted)\nIn-text: \($0.inText)" }.joined(separator: "\n\n---\n\n")
        case .bibtex:
            return savedCitations.enumerated().map { i, c in
                "@misc{ref\(i + 1),\n  title = {\(c.formatted)},\n  note = {\(c.style)}\n}"
            }.joined(separator: "\n\n")
        case .ris:
            return savedCitations.map { c in
                "TY  - GEN\nTI  - \(c.formatted)\nN1  - \(c.style)\nER  -"
            }.joined(separator: "\n\n")
        case .endnote:
            let entries = savedCitations.map { "<record><titles><title>\($0.formatted)</title></titles><notes>\($0.style)</notes></record>" }.joined()
            return "<?xml version=\"1.0\"?>\n<xml><records>\(entries)</records></xml>"
        }
    }

    func checkDuplicates() {
        var seen: Set<String> = []
        duplicateWarnings = []
        for citation in savedCitations {
            let normalized = citation.formatted.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            if seen.contains(normalized) {
                duplicateWarnings.append(citation.formatted)
            } else {
                seen.insert(normalized)
            }
        }
    }

    func addToGroup(_ citation: GeneratedCitation, groupName: String) {
        if let idx = citationGroups.firstIndex(where: { $0.name == groupName }) {
            citationGroups[idx].citations.append(citation)
        } else {
            citationGroups.append(CitationGroup(name: groupName, citations: [citation]))
        }
    }

    var sortedSavedCitations: [GeneratedCitation] {
        switch sortOrder {
        case .dateAdded: return savedCitations
        case .authorAZ: return savedCitations.sorted { $0.formatted < $1.formatted }
        case .yearDesc, .yearAsc: return savedCitations
        case .styleGroup: return savedCitations.sorted { $0.style < $1.style }
        }
    }
}

struct CitationGroup: Identifiable {
    let id = UUID()
    var name: String
    var citations: [GeneratedCitation]
}

// MARK: - Main View

struct CitationFormatsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CitationFormatsViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                tabBar
                Divider()

                switch viewModel.selectedTab {
                case .templates:
                    templatesTab
                case .generator:
                    generatorTab
                case .saved:
                    savedTab
                case .bibliography:
                    bibliographyTab
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Citations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(CitationFormatsViewModel.CitationTab.allCases, id: \.rawValue) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: tabIcon(tab))
                            .font(.system(size: 16, weight: .medium))
                        Text(tab.rawValue)
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundColor(viewModel.selectedTab == tab ? .accentColor : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        viewModel.selectedTab == tab
                            ? Color.accentColor.opacity(0.1)
                            : Color.clear,
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    private func tabIcon(_ tab: CitationFormatsViewModel.CitationTab) -> String {
        switch tab {
        case .templates: return "doc.text.magnifyingglass"
        case .generator: return "wand.and.stars"
        case .saved: return "bookmark.fill"
        case .bibliography: return "books.vertical.fill"
        }
    }

    // MARK: - Templates Tab

    private var templatesTab: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                    TextField("Search Citation Styles", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                    if !viewModel.searchText.isEmpty {
                        Button { viewModel.searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            }
            .listRowBackground(Color.clear)

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Quick Tip", systemImage: "lightbulb.fill")
                        .font(.caption.bold())
                        .foregroundColor(.orange)
                    Text("Tap any citation to copy. Long-press to see in-text format. Use the Generator tab to create citations from your own sources.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            }
            .listRowBackground(Color.clear)

            citationSection("Academic Styles", citations: academicCitations)
            citationSection("Legal & Government", citations: legalCitations)
            citationSection("Science & Medicine", citations: scienceCitations)
            citationSection("Business & Reports", citations: businessCitations)
            citationSection("Web & Digital", citations: webCitations)
            citationSection("Books & Chapters", citations: bookCitations)
            citationSection("Thesis & Dissertations", citations: thesisCitations)
            citationSection("Conference & Presentations", citations: conferenceCitations)
            citationSection("Film, Music, Podcasts", citations: mediaCitations)
            citationSection("Miscellaneous", citations: miscCitations)
        }
    }

    @ViewBuilder
    private func citationSection(_ title: String, citations: [(String, String, String, String)]) -> some View {
        let filtered = viewModel.searchText.isEmpty
            ? citations
            : citations.filter {
                $0.0.localizedCaseInsensitiveContains(viewModel.searchText) ||
                $0.1.localizedCaseInsensitiveContains(viewModel.searchText)
            }

        if !filtered.isEmpty {
            Section(title) {
                ForEach(filtered, id: \.0) { item in
                    CitationTemplateRow(
                        name: item.0,
                        description: item.1,
                        format: item.2,
                        inTextExample: item.3
                    )
                }
            }
        }
    }

    // MARK: - Generator Tab

    private var generatorTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                sourceTypeSelector
                fieldEntrySection
                styleSelector
                generateButton

                if viewModel.isGenerating {
                    ProgressView("Generating citations...")
                        .padding()
                }

                if !viewModel.generatedCitations.isEmpty {
                    generatedResults
                }
            }
            .padding()
        }
    }

    private var sourceTypeSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Source Type", systemImage: "doc.badge.gearshape")
                .font(.subheadline.bold())
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CitationSourceType.allCases) { type in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                viewModel.selectedSourceType = type
                            }
                        } label: {
                            Label(type.rawValue, systemImage: type.icon)
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    viewModel.selectedSourceType == type
                                        ? Color.accentColor
                                        : Color(.tertiarySystemBackground)
                                )
                                .foregroundColor(
                                    viewModel.selectedSourceType == type ? .white : .primary
                                )
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().stroke(
                                        viewModel.selectedSourceType == type
                                            ? Color.clear
                                            : Color(.separator),
                                        lineWidth: 1
                                    )
                                )
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var fieldEntrySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Source Details", systemImage: "square.and.pencil")
                    .font(.subheadline.bold())
                Spacer()
                Button("Clear") {
                    viewModel.clearFields()
                }
                .font(.caption)
                .foregroundColor(.red)
            }

            generatorField("Last Name", text: $viewModel.authorLast, icon: "person", required: true)
            generatorField("First Name", text: $viewModel.authorFirst, icon: "person")
            generatorField("Title", text: $viewModel.title, icon: "text.quote", required: true)
            generatorField("Year", text: $viewModel.year, icon: "calendar", required: true)

            switch viewModel.selectedSourceType {
            case .book:
                generatorField("Publisher", text: $viewModel.publisher, icon: "building.2")
                generatorField("City", text: $viewModel.city, icon: "mappin")
                generatorField("Edition", text: $viewModel.edition, icon: "number")
                generatorField("Editor", text: $viewModel.editor, icon: "person.2")
                generatorField("Chapter", text: $viewModel.chapterTitle, icon: "bookmark")
                generatorField("DOI", text: $viewModel.doi, icon: "link")
            case .journalArticle:
                generatorField("Journal", text: $viewModel.journalName, icon: "newspaper")
                generatorField("Volume", text: $viewModel.volume, icon: "number")
                generatorField("Issue", text: $viewModel.issue, icon: "number")
                generatorField("Pages", text: $viewModel.pages, icon: "doc.plaintext")
                generatorField("DOI", text: $viewModel.doi, icon: "link")
            case .website:
                generatorField("URL", text: $viewModel.url, icon: "globe")
                generatorField("Access Date", text: $viewModel.accessDate, icon: "calendar.badge.clock")
                generatorField("Site Name", text: $viewModel.publisher, icon: "building.2")
            case .conferenceProceeding:
                generatorField("Conference", text: $viewModel.journalName, icon: "person.3")
                generatorField("City", text: $viewModel.city, icon: "mappin")
                generatorField("Pages", text: $viewModel.pages, icon: "doc.plaintext")
                generatorField("DOI", text: $viewModel.doi, icon: "link")
            case .thesis:
                generatorField("University", text: $viewModel.publisher, icon: "graduationcap")
                generatorField("Degree Type", text: $viewModel.edition, icon: "scroll")
                generatorField("Database", text: $viewModel.journalName, icon: "externaldrive")
            case .film:
                generatorField("Studio", text: $viewModel.publisher, icon: "film")
                generatorField("Role", text: $viewModel.edition, icon: "person.crop.rectangle")
                generatorField("URL", text: $viewModel.url, icon: "globe")
            case .podcast:
                generatorField("Podcast Name", text: $viewModel.journalName, icon: "mic")
                generatorField("Episode No.", text: $viewModel.issue, icon: "number")
                generatorField("Network", text: $viewModel.publisher, icon: "antenna.radiowaves.left.and.right")
                generatorField("URL", text: $viewModel.url, icon: "globe")
            case .socialMedia:
                generatorField("Platform", text: $viewModel.publisher, icon: "at")
                generatorField("Handle", text: $viewModel.edition, icon: "person.circle")
                generatorField("URL", text: $viewModel.url, icon: "globe")
            case .governmentDoc:
                generatorField("Agency", text: $viewModel.publisher, icon: "building.columns")
                generatorField("Report No.", text: $viewModel.volume, icon: "number")
                generatorField("URL", text: $viewModel.url, icon: "globe")
            case .patent:
                generatorField("Patent No.", text: $viewModel.volume, icon: "number")
                generatorField("Country", text: $viewModel.city, icon: "flag")
                generatorField("Office", text: $viewModel.publisher, icon: "building.columns")
            case .interview:
                generatorField("Type", text: $viewModel.edition, icon: "bubble.left.and.bubble.right")
                generatorField("Date", text: $viewModel.accessDate, icon: "calendar")
            case .software:
                generatorField("Version", text: $viewModel.edition, icon: "number")
                generatorField("Platform", text: $viewModel.publisher, icon: "desktopcomputer")
                generatorField("URL", text: $viewModel.url, icon: "globe")
            }

            if !viewModel.additionalAuthors.isEmpty {
                ForEach(0..<viewModel.additionalAuthors.count, id: \.self) { index in
                    HStack {
                        generatorField("Author \(index + 2)", text: $viewModel.additionalAuthors[index], icon: "person.2")
                        Button {
                            viewModel.additionalAuthors.remove(at: index)
                        } label: {
                            Image(systemName: "minus.circle.fill").foregroundColor(.red)
                        }
                    }
                }
            }

            Button {
                viewModel.additionalAuthors.append("")
            } label: {
                Label("Add Another Author", systemImage: "person.badge.plus")
                    .font(.caption.bold())
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func generatorField(_ label: String, text: Binding<String>, icon: String, required: Bool = false) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(label).font(.caption2).foregroundColor(.secondary)
                    if required {
                        Text("*").font(.caption2).foregroundColor(.red)
                    }
                }
                TextField(label, text: text)
                    .font(.subheadline)
                    .textFieldStyle(.plain)
            }
        }
        .padding(10)
        .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
    }

    private var styleSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Output Styles", systemImage: "text.badge.checkmark")
                .font(.subheadline.bold())
            Text("Select which citation styles to generate simultaneously.")
                .font(.caption2)
                .foregroundColor(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130))], spacing: 8) {
                ForEach(CitationFormatStyle.allCases) { style in
                    Button {
                        if viewModel.selectedStyles.contains(style.rawValue) {
                            viewModel.selectedStyles.remove(style.rawValue)
                        } else {
                            viewModel.selectedStyles.insert(style.rawValue)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: viewModel.selectedStyles.contains(style.rawValue) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(viewModel.selectedStyles.contains(style.rawValue) ? .accentColor : .secondary)
                                .font(.caption)
                            Text(style.rawValue)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            viewModel.selectedStyles.contains(style.rawValue)
                                ? Color.accentColor.opacity(0.1)
                                : Color(.tertiarySystemBackground),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10).stroke(
                                viewModel.selectedStyles.contains(style.rawValue)
                                    ? Color.accentColor.opacity(0.4)
                                    : Color.clear,
                                lineWidth: 1
                            )
                        )
                    }
                }
            }

            HStack(spacing: 12) {
                Button("Select All") {
                    viewModel.selectedStyles = Set(CitationFormatStyle.allCases.map(\.rawValue))
                }
                .font(.caption.bold())
                Button("Clear All") {
                    viewModel.selectedStyles.removeAll()
                }
                .font(.caption.bold())
                .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var generateButton: some View {
        Button {
            viewModel.generateCitations()
        } label: {
            Label(viewModel.isGenerating ? "Generating..." : "Generate Citations", systemImage: "wand.and.stars")
                .bold()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    (viewModel.title.isEmpty || viewModel.authorLast.isEmpty || viewModel.selectedStyles.isEmpty)
                        ? Color.gray
                        : Color.accentColor
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(viewModel.title.isEmpty || viewModel.authorLast.isEmpty || viewModel.selectedStyles.isEmpty || viewModel.isGenerating)
    }

    private var generatedResults: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Generated Citations", systemImage: "checkmark.seal")
                    .font(.subheadline.bold())
                Spacer()
                Text("\(viewModel.generatedCitations.count) styles")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ForEach(viewModel.generatedCitations) { citation in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(citation.style)
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.15), in: Capsule())
                        Spacer()
                        Button {
                            UIPasteboard.general.string = citation.formatted
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Image(systemName: "doc.on.doc").font(.caption)
                        }
                        Button {
                            viewModel.saveCitation(citation)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Image(systemName: "bookmark").font(.caption)
                        }
                    }

                    Text(citation.formatted)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 4) {
                        Text("In-text:")
                            .font(.caption2.bold())
                            .foregroundColor(.secondary)
                        Text(citation.inText)
                            .font(.caption2)
                            .foregroundColor(.accentColor)
                        Spacer()
                        Button {
                            UIPasteboard.general.string = citation.inText
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Text("Copy In-text")
                                .font(.caption2.bold())
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Saved Tab

    private var savedTab: some View {
        Group {
            if viewModel.savedCitations.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "bookmark.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No Saved Citations")
                        .font(.headline)
                    Text("Generate citations and tap the bookmark icon to save them here.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .padding()
            } else {
                List {
                    Section {
                        HStack {
                            Label("Sort", systemImage: "arrow.up.arrow.down")
                                .font(.caption.bold()).foregroundStyle(.secondary)
                            Picker("Sort", selection: $viewModel.sortOrder) {
                                ForEach(CitationFormatsViewModel.SortOrder.allCases, id: \.rawValue) {
                                    Text($0.rawValue).tag($0)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()

                            Spacer()

                            Text("\(viewModel.savedCitations.count) citation(s)")
                                .font(.caption2).foregroundStyle(.secondary)
                        }

                        if !viewModel.duplicateWarnings.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange).font(.caption)
                                Text("\(viewModel.duplicateWarnings.count) duplicate(s) detected")
                                    .font(.caption2.bold()).foregroundStyle(.orange)
                            }
                        }

                        HStack(spacing: 8) {
                            Button {
                                viewModel.checkDuplicates()
                            } label: {
                                Label("Check Duplicates", systemImage: "doc.on.doc.fill")
                                    .font(.caption2.bold())
                            }
                            .buttonStyle(.bordered).controlSize(.small)

                            Picker("Export", selection: $viewModel.exportFormat) {
                                ForEach(CitationFormatsViewModel.ExportFormat.allCases, id: \.rawValue) {
                                    Text($0.rawValue).tag($0)
                                }
                            }
                            .pickerStyle(.menu).controlSize(.small)

                            ShareLink(item: viewModel.exportAllSaved()) {
                                Label("Export", systemImage: "square.and.arrow.up")
                                    .font(.caption2.bold())
                            }
                            .buttonStyle(.bordered).controlSize(.small)
                        }
                    }
                    .listRowBackground(Color.clear)

                    ForEach(viewModel.sortedSavedCitations) { citation in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(citation.style)
                                    .font(.caption.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.accentColor.opacity(0.15), in: Capsule())
                                Spacer()
                                Button {
                                    UIPasteboard.general.string = citation.formatted
                                } label: {
                                    Image(systemName: "doc.on.doc").font(.caption)
                                }
                            }
                            Text(citation.formatted)
                                .font(.caption)
                                .fixedSize(horizontal: false, vertical: true)
                            HStack(spacing: 4) {
                                Text("In-text:").font(.caption2.bold()).foregroundColor(.secondary)
                                Text(citation.inText).font(.caption2).foregroundColor(.accentColor)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { indices in
                        viewModel.savedCitations.remove(atOffsets: indices)
                    }
                }
            }
        }
    }

    // MARK: - Bibliography Tab

    @State private var newGroupName = ""

    private var bibliographyTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Bibliography Builder", systemImage: "books.vertical.fill")
                        .font(.headline)
                    Text("Organize citations into groups to build structured bibliographies for your papers.")
                        .font(.caption).foregroundColor(.secondary)

                    HStack {
                        TextField("New group name...", text: $newGroupName)
                            .textFieldStyle(.roundedBorder)
                        Button("Create") {
                            guard !newGroupName.isEmpty else { return }
                            viewModel.citationGroups.append(CitationGroup(name: newGroupName, citations: []))
                            newGroupName = ""
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(newGroupName.isEmpty)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                if viewModel.citationGroups.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No Bibliography Groups")
                            .font(.headline)
                        Text("Create groups to organize your saved citations into bibliographies.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 40)
                } else {
                    ForEach($viewModel.citationGroups) { $group in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "folder.fill").foregroundColor(.accentColor)
                                Text(group.name).font(.subheadline.bold())
                                Spacer()
                                Text("\(group.citations.count) item(s)")
                                    .font(.caption2).foregroundColor(.secondary)
                            }

                            if group.citations.isEmpty {
                                Text("Drag citations here or add from Saved tab.")
                                    .font(.caption2).foregroundColor(.secondary).italic()
                                    .padding(.vertical, 8)
                            } else {
                                ForEach(group.citations) { citation in
                                    HStack(spacing: 8) {
                                        Text(citation.style)
                                            .font(.system(size: 8, weight: .bold))
                                            .padding(.horizontal, 6).padding(.vertical, 2)
                                            .background(Color.accentColor.opacity(0.15), in: Capsule())
                                        Text(citation.formatted)
                                            .font(.caption2).lineLimit(1)
                                        Spacer()
                                    }
                                    .padding(6)
                                    .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 6))
                                }
                            }

                            HStack(spacing: 8) {
                                ShareLink(item: group.citations.map(\.formatted).joined(separator: "\n\n")) {
                                    Label("Export Group", systemImage: "square.and.arrow.up")
                                        .font(.caption2.bold())
                                }
                                .buttonStyle(.bordered).controlSize(.small)

                                Button {
                                    UIPasteboard.general.string = group.citations.map(\.formatted).joined(separator: "\n\n")
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                } label: {
                                    Label("Copy All", systemImage: "doc.on.doc")
                                        .font(.caption2.bold())
                                }
                                .buttonStyle(.bordered).controlSize(.small)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Label("Quick Add from Saved", systemImage: "plus.circle.fill")
                        .font(.subheadline.bold())

                    if viewModel.savedCitations.isEmpty {
                        Text("No saved citations to add. Generate and save citations first.")
                            .font(.caption).foregroundColor(.secondary)
                    } else if viewModel.citationGroups.isEmpty {
                        Text("Create a group above first.")
                            .font(.caption).foregroundColor(.secondary)
                    } else {
                        ForEach(viewModel.savedCitations) { citation in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(citation.style).font(.caption2.bold()).foregroundColor(.accentColor)
                                    Text(citation.formatted).font(.caption2).lineLimit(1)
                                }
                                Spacer()
                                Menu {
                                    ForEach(viewModel.citationGroups) { group in
                                        Button(group.name) {
                                            viewModel.addToGroup(citation, groupName: group.name)
                                        }
                                    }
                                } label: {
                                    Label("Add to...", systemImage: "folder.badge.plus")
                                        .font(.caption2.bold())
                                }
                                .controlSize(.small)
                            }
                            .padding(8)
                            .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
    }

    // MARK: - Template Data

    private var academicCitations: [(String, String, String, String)] {
        [
            ("APA 7th Edition", "Psychology, education, sciences.", "Smith, J. (2024). *The Future of AI*. Tech Press. https://doi.org/10.1234/5678", "(Smith, 2024)"),
            ("MLA 9th Edition", "Humanities, literature, cultural studies.", "Smith, John. \"The Future of AI.\" *Journal of Technology*, vol. 12, no. 3, 2024, pp. 45–67.", "(Smith 45)"),
            ("Chicago 17th (Author-Date)", "Physical, natural, social sciences.", "Smith, John. 2024. *The Future of AI*. San Francisco: Tech Press.", "(Smith 2024)"),
            ("Chicago 17th (Notes-Bibliography)", "History and the arts.", "Smith, John. *The Future of AI*. San Francisco: Tech Press, 2024.", "Smith, *Future*, 12."),
            ("Harvard", "UK and Australian universities.", "Smith, J. (2024) *The Future of AI*. San Francisco: Tech Press.", "(Smith 2024)"),
            ("Turabian 9th", "Student papers (Chicago variation).", "Smith, John. *The Future of AI*. San Francisco: Tech Press, 2024.", "(Smith 2024, 45)"),
            ("Vancouver", "Medicine, biological sciences.", "Smith J. The Future of AI. Tech Jour. 2024 Jan;12(3):45-67. doi:10.1234/5678", "(1)"),
            ("IEEE", "Engineering, computer science, IT.", "[1] J. Smith, \"The Future of AI,\" *Journal of Technology*, vol. 12, no. 3, pp. 45–67, Jan. 2024.", "[1]"),
            ("ACS", "American Chemical Society.", "Smith, J.; Doe, B. *Chem. Tech. Jour.* **2024**, *12*, 45-67.", "(1)"),
            ("AMA", "American Medical Association.", "Smith J, Doe B. The Future of AI. *Journal Name*. 2024;12(3):45-67. doi:10.1234/5678", "¹"),
            ("ASA", "American Sociological Association.", "Smith, John. 2024. \"The Future of AI.\" *Social Tech Journal* 12(3):45-67.", "(Smith 2024)"),
            ("APSA", "American Political Science Association.", "Smith, John. 2024. *The Future of AI*. San Francisco: Tech Press.", "(Smith 2024)"),
            ("AAA", "American Anthropological Association.", "Smith, John. 2024. The Future of AI. *Anthr. Tech.* 12(3):45-67.", "(Smith 2024)"),
            ("CSE Name-Year", "Council of Science Editors.", "Smith J, Doe B. 2024. The Future of AI. Sci Tech J. 12:45-67.", "(Smith 2024)"),
            ("NLM", "National Library of Medicine.", "Smith J, Doe B. The future of AI. Sci Tech J. 2024 Jan;12(3):45-67.", "(1)")
        ]
    }

    private var legalCitations: [(String, String, String, String)] {
        [
            ("Bluebook Brief", "Citation for legal briefs.", "Brief for Petitioner at 12, Smith v. Jones, 123 U.S. 456 (2024).", "Smith v. Jones, 123 U.S. 456"),
            ("Legal Case (US)", "Standard US legal case citation.", "Smith v. Jones, 123 F.3d 456 (9th Cir. 2024).", "Smith, 123 F.3d at 460"),
            ("Bluebook (Law Review)", "Uniform system for legal documents.", "John Smith, *The Future of AI*, 12 Tech. J. 45 (2024).", "Smith, supra note 1, at 50"),
            ("OSCOLA", "Oxford Standard for Legal Authorities.", "John Smith, *The Future of AI* (Tech Press 2024) 45.", "Smith (n 1) 45"),
            ("AGLC4", "Australian Guide to Legal Citation.", "John Smith, *The Future of AI* (Tech Press, 2024) 45.", "Smith (n 1) 45")
        ]
    }

    private var scienceCitations: [(String, String, String, String)] {
        [
            ("Nature", "Standard for Nature journals.", "Smith, J. et al. The Future of AI. *Nature* 12, 45-67 (2024). https://doi.org/10.1234/5678", "¹"),
            ("APA PsycInfo Journal", "APA for psychology journals.", "Smith, J., & Doe, B. (2024). The Future of AI. *Psychology of Tech, 12*(3), pp. 45–67. https://doi.org/10.1234/5678", "(Smith & Doe, 2024)")
        ]
    }

    private var businessCitations: [(String, String, String, String)] {
        [
            ("APA Report", "Professional and technical reports.", "Smith, J. (2024). *The Future of AI* (Report No. 123). AI Agency. https://agency.gov/report", "(Smith, 2024)"),
            ("Government Document", "Official government publications.", "National AI Agency. (2024). *The Future of AI*. Government Printing Office. https://agency.gov/doc", "(National AI Agency, 2024)"),
            ("Press Release", "Company announcements.", "Tech Corp. (2024, May 20). *Announcing The Future of AI* [Press release]. https://techcorp.com/news", "(Tech Corp., 2024)")
        ]
    }

    private var webCitations: [(String, String, String, String)] {
        [
            ("APA Website", "Open web content.", "Smith, J. (2024, May 20). *The Future of AI*. Tech Today. https://techtoday.com/ai", "(Smith, 2024)"),
            ("MLA Website", "Web citation for humanities.", "Smith, John. \"The Future of AI.\" *Tech Today*, 20 May 2024, https://techtoday.com/ai.", "(Smith)"),
            ("APA Social Media", "Tweets, posts, social content.", "Smith, J. [@jsmith]. (2024, May 20). *Excited to share my thoughts on the future of AI!* [Tweet]. X. https://x.com/jsmith/status/123", "(Smith, 2024)"),
            ("Wikipedia", "Wiki entries.", "\"The Future of AI.\" *Wikipedia*, Wikimedia Foundation, 20 May 2024, https://en.wikipedia.org/wiki/Future_of_AI.", "(\"Future of AI\")")
        ]
    }

    private var bookCitations: [(String, String, String, String)] {
        [
            ("APA Book Chapter", "Chapter within an edited book.", "Smith, J. (2024). The Future of AI. In B. Doe (Ed.), *Tech Anthology* (pp. 45–67). Tech Press.", "(Smith, 2024)"),
            ("MLA Book", "Standard MLA book citation.", "Smith, John. *The Future of AI*. Tech Press, 2024.", "(Smith 12)"),
            ("Chicago Book (N-B)", "Notes-Bibliography for books.", "Smith, John. *The Future of AI*. San Francisco: Tech Press, 2024.", "Smith, *Future*, 12."),
            ("Edited Volume", "Complete edited collection.", "Smith, John, ed. *The Future of AI*. San Francisco: Tech Press, 2024.", "(Smith 2024)")
        ]
    }

    private var thesisCitations: [(String, String, String, String)] {
        [
            ("APA Dissertation", "Doctoral-level research.", "Smith, J. (2024). *The Future of AI* [Doctoral dissertation, Tech University]. ProQuest Database.", "(Smith, 2024)"),
            ("MLA Thesis", "Master's-level research.", "Smith, John. \"The Future of AI.\" Master's thesis, Tech University, 2024.", "(Smith 14)")
        ]
    }

    private var conferenceCitations: [(String, String, String, String)] {
        [
            ("APA Conference Paper", "Papers presented at conferences.", "Smith, J. (2024, May). *The Future of AI* [Paper presentation]. AI World 2024, San Francisco.", "(Smith, 2024)"),
            ("IEEE Conference", "IEEE for conference proceedings.", "[1] J. Smith, \"The Future of AI,\" in *Proc. AI World*, San Francisco, 2024, pp. 45–67.", "[1]")
        ]
    }

    private var mediaCitations: [(String, String, String, String)] {
        [
            ("APA Film", "Films or documentaries.", "Smith, J. (Director). (2024). *The Future of AI* [Film]. AI Studios.", "(Smith, 2024)"),
            ("MLA Film", "MLA for audiovisual work.", "*The Future of AI*. Directed by John Smith, AI Studios, 2024.", "(*Future of AI*)"),
            ("APA Podcast Episode", "Individual podcast episodes.", "Smith, J. (Host). (2024, May 20). The Future of AI (No. 42) [Audio podcast episode]. In *Tech Talk*. AI Network. https://techtalk.fm/42", "(Smith, 2024)"),
            ("APA Song", "Individual songs.", "The AI Band. (2024). *The Future of AI* [Song]. On *Digital Dreams*. Synth Label.", "(The AI Band, 2024)"),
            ("Movie Script", "Citing screenplays.", "Smith, John. *The Future of AI*. Screenplay, 2024.", "(Smith 2024)")
        ]
    }

    private var miscCitations: [(String, String, String, String)] {
        [
            ("Personal Interview", "Private interview.", "Smith, John. Personal interview. 20 May 2024.", "(Smith, personal communication, May 20, 2024)"),
            ("Lecture", "Live presentation or lecture.", "Smith, John. \"The Future of AI.\" Guest Lecture, University of Tech, 20 May 2024.", "(Smith 2024)"),
            ("Software", "Computer software or apps.", "Smith, J. (2024). *Tools-Kit* (Version 1.0) [Mobile app]. App Store.", "(Smith, 2024)"),
            ("Standard", "Technical standards (ISO, ANSI).", "International Organization for Standardization. (2024). *Information technology* (ISO Standard No. 12345).", "(ISO, 2024)"),
            ("Patent", "Official patent.", "Smith, John. (2024). U.S. Patent No. 1,234,567. Washington, DC: U.S. Patent and Trademark Office.", "(Smith, 2024)")
        ]
    }
}

// MARK: - Citation Template Row

struct CitationTemplateRow: View {
    let name: String
    let description: String
    let format: String
    let inTextExample: String

    @State private var showInText = false
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name)
                    .font(.subheadline.bold())
                Spacer()
                if copied {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                        .transition(.scale.combined(with: .opacity))
                }
            }

            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    Text("Ref:")
                        .font(.caption2.bold())
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .leading)
                    Text(format)
                        .font(.caption.italic())
                        .foregroundColor(.blue)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(alignment: .top) {
                    Text("In-text:")
                        .font(.caption2.bold())
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .leading)
                    Text(inTextExample)
                        .font(.caption)
                        .foregroundColor(.purple)
                }
            }
            .padding(10)
            .background(Color.blue.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            HStack(spacing: 12) {
                Button {
                    UIPasteboard.general.string = format
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation { copied = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { copied = false }
                    }
                } label: {
                    Label("Copy Reference", systemImage: "doc.on.doc")
                        .font(.caption2.bold())
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)

                Button {
                    UIPasteboard.general.string = inTextExample
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Label("Copy In-text", systemImage: "text.quote")
                        .font(.caption2.bold())
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
            }
        }
        .padding(.vertical, 6)
    }
}
