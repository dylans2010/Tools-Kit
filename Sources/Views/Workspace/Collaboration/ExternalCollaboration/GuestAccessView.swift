import SwiftUI
#if os(iOS)
import UIKit
#endif
struct GuestAccessView: View {
    let spaceID: UUID
    var body: some View {
        Button("Copy Invite Link") {
            #if os(iOS)
            UIPasteboard.general.string = "link"
            #endif
        }
    }
}