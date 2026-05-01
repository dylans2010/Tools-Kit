import SwiftUI
#if os(iOS)
import UIKit
#endif
struct GuestAccessView: View {
    var body: some View {
        Button("Copy Link") {
            #if os(iOS)
            UIPasteboard.general.string = "link"
            #endif
        }
    }
}