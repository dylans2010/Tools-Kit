import SwiftUI

struct WorkspaceHomeView: View {
    @State private var selectedTab: WorkspaceTab = .notes

    enum WorkspaceTab: String, CaseIterable {
        case notes  = "Notes"
        case forms  = "Forms"
        case slides = "Slides"

        var icon: String {
            switch self {
            case .notes:  return "note.text"
            case .forms:  return "list.bullet.rectangle.portrait"
            case .slides: return "rectangle.on.rectangle.angled"
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
        }
    }
}
