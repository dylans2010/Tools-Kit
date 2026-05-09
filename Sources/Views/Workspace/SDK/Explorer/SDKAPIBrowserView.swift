/*
 REDESIGN SUMMARY:
 - Standardized as a navigation wrapper for SDKAPIExplorerView.
 - Applied inline navigation title display mode.
 */

import SwiftUI

struct SDKAPIBrowserView: View {
    var body: some View {
        SDKAPIExplorerView()
            .navigationTitle("API Browser")
            .navigationBarTitleDisplayMode(.inline)
    }
}
