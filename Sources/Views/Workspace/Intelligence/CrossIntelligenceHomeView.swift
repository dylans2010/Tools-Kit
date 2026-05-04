import SwiftUI

struct CrossIntelligenceHomeView: View {
    var body: some View {
        List {
            NavigationLink(destination: GlobalSearchView()) {
                Label("Semantic Search", systemImage: "magnifyingglass")
            }
            NavigationLink(destination: AskWorkspaceView()) {
                Label("Ask Workspace", systemImage: "sparkles")
            }
            NavigationLink(destination: GraphExplorerView()) {
                Label("Context Graph", systemImage: "network")
            }
        }
        .navigationTitle("Intelligence")
    }
}
