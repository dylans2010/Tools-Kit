import SwiftUI

struct MeetingWebView: View {
    @ObservedObject var controller: MeetSessionController

    var body: some View {
        MeetingContainerView(manager: controller)
    }
}
