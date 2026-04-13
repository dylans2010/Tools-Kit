import SwiftUI

struct WorkspaceHomeView: View {
    @State private var selectedTab: WorkspaceTab = .notes

    enum WorkspaceTab: String, CaseIterable {
        case notes       = "Notes"
        case forms       = "Forms"
        case slides      = "Slides"
        case articles    = "Articles"
        case spreadsheets = "Sheets"
        case notebooks   = "Notebooks"

        var icon: String {
            switch self {
            case .notes:        return "note.text"
            case .forms:        return "list.bullet.rectangle.portrait"
            case .slides:       return "rectangle.on.rectangle.angled"
            case .articles:     return "newspaper"
            case .spreadsheets: return "tablecells"
            case .notebooks:    return "book.closed"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                NotesView()
            }
            .tabItem {
                Label(WorkspaceTab.notes.rawValue, systemImage: WorkspaceTab.notes.icon)
            }
            .tag(WorkspaceTab.notes)

            NavigationStack {
                FormsView()
            }
            .tabItem {
                Label(WorkspaceTab.forms.rawValue, systemImage: WorkspaceTab.forms.icon)
            }
            .tag(WorkspaceTab.forms)

            NavigationStack {
                SlidesHomeView()
            }
            .tabItem {
                Label(WorkspaceTab.slides.rawValue, systemImage: WorkspaceTab.slides.icon)
            }
            .tag(WorkspaceTab.slides)

            NavigationStack {
                ArticlesHomeView()
            }
            .tabItem {
                Label(WorkspaceTab.articles.rawValue, systemImage: WorkspaceTab.articles.icon)
            }
            .tag(WorkspaceTab.articles)

            NavigationStack {
                SpreadsheetsHomeView()
            }
            .tabItem {
                Label(WorkspaceTab.spreadsheets.rawValue, systemImage: WorkspaceTab.spreadsheets.icon)
            }
            .tag(WorkspaceTab.spreadsheets)

            NavigationStack {
                NotebooksHomeView()
            }
            .tabItem {
                Label(WorkspaceTab.notebooks.rawValue, systemImage: WorkspaceTab.notebooks.icon)
            }
            .tag(WorkspaceTab.notebooks)
        }
    }
}
