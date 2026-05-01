import SwiftUI

struct MeetDeveloperToolsView: View {
    @ObservedObject var manager: MeetingStateManager

    var body: some View {
        List {
            NavigationLink("Meet Debug Console") {
                DebugView(manager: manager)
            }
        }
        .navigationTitle("Developer Tools")
    }
}
