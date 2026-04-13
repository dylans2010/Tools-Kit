import SwiftUI

struct WorkspaceHomeView: View {
    @State private var selectedTab: WorkspaceTab = .notes

    enum WorkspaceTab: String, CaseIterable {
        case notes   = "Notes"
        case forms   = "Forms"
        case slides  = "Slides"
        case habits  = "Habits"
        case tasks   = "Tasks"
        case calendar = "Calendar"

        var icon: String {
            switch self {
            case .notes:    return "note.text"
            case .forms:    return "list.bullet.rectangle.portrait"
            case .slides:   return "rectangle.on.rectangle.angled"
            case .habits:   return "flame.fill"
            case .tasks:    return "checklist"
            case .calendar: return "calendar"
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
                WorkspaceHabitTrackerView()
            }
            .tabItem {
                Label(WorkspaceTab.habits.rawValue, systemImage: WorkspaceTab.habits.icon)
            }
            .tag(WorkspaceTab.habits)

            NavigationStack {
                TasksHomeView()
            }
            .tabItem {
                Label(WorkspaceTab.tasks.rawValue, systemImage: WorkspaceTab.tasks.icon)
            }
            .tag(WorkspaceTab.tasks)

            NavigationStack {
                CalendarHomeView()
            }
            .tabItem {
                Label(WorkspaceTab.calendar.rawValue, systemImage: WorkspaceTab.calendar.icon)
            }
            .tag(WorkspaceTab.calendar)
        }
    }
}
