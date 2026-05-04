import SwiftUI

struct RepoTasksView: View {
    let repo: String

    var body: some View {
        List {
            Text("Tasks synced from \(repo)")
            Label("Fix memory leak", systemImage: "bug")
            Label("Optimize image loading", systemImage: "speedometer")
        }
        .navigationTitle("Repo Tasks")
    }
}
