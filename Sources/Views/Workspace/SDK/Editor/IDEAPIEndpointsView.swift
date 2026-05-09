/*
 REDESIGN SUMMARY:
 - Standardized as a navigation wrapper for SDKAPIExplorerView.
 - Applied inline navigation title display mode.
 */

import SwiftUI

struct IDEAPIEndpointsView: View {
    var body: some View {
        SDKAPIExplorerView()
            .navigationTitle("API Endpoints")
            .navigationBarTitleDisplayMode(.inline)
    }
}
