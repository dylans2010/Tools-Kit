import SwiftUI

/// Consolidated API browser to avoid overlap with SDKAPIExplorerView.
struct SDKAPIBrowserView: View {
    var body: some View {
        SDKAPIExplorerView()
            .navigationTitle("API Browser")
    }
}
