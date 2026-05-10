import SwiftUI

struct WorkspaceHomeView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Workspace") {
                    NavigationLink {
                        NotesView()
                    } label: {
                        Label("Notes", systemImage: "note.text")
                    }
                    NavigationLink {
                        TasksHomeView()
                    } label: {
                        Label("Tasks", systemImage: "checklist")
                    }
                    NavigationLink {
                        FileManagementView()
                    } label: {
                        Label("Files", systemImage: "folder")
                    }
                    NavigationLink {
                        CalendarHomeView()
                    } label: {
                        Label("Calendar", systemImage: "calendar")
                    }
                }

                Section("Creation") {
                    NavigationLink {
                        NotebooksHomeView()
                    } label: {
                        Label("Notebooks", systemImage: "book.closed")
                    }
                    NavigationLink {
                        ArticlesHomeView()
                    } label: {
                        Label("Articles", systemImage: "newspaper")
                    }
                    NavigationLink {
                        EditingHomeView()
                    } label: {
                        Label("Media Editing", systemImage: "photo.stack")
                    }
                    NavigationLink {
                        SlidesHomeView()
                    } label: {
                        Label("Slides", systemImage: "rectangle.on.rectangle")
                    }
                }

                Section("System Entry") {
                    NavigationLink {
                        SDKHomeView()
                    } label: {
                        Label("SDK", systemImage: "hammer")
                    }
                    NavigationLink {
                        PluginsMainView()
                    } label: {
                        Label("Plugins", systemImage: "puzzlepiece.extension")
                    }
                    NavigationLink {
                        ConnectorsMainView()
                    } label: {
                        Label("Connectors", systemImage: "cable.connector")
                    }
                    NavigationLink {
                        SecurityHomeView()
                    } label: {
                        Label("Security", systemImage: "lock.shield")
                    }
                    NavigationLink {
                        GitHubRouterView()
                    } label: {
                        Label("GitHub", systemImage: "terminal")
                    }
                }
            }
            .navigationTitle("Workspace")
        }
        .withPluginOverlay()
    }
}
