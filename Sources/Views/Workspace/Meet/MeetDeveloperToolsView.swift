import SwiftUI

struct MeetDeveloperToolsView: View {
    var body: some View {
        List {
            NavigationLink("Meet Debug Console") {
                DebugView()
            }
        }
        .navigationTitle("Developer Tools")
    }
}
