/*
 REDESIGN SUMMARY:
 - Standardized as a navigation wrapper for IDEScopesView.
 - Applied inline navigation title display mode.
 */

import SwiftUI

struct SDKScopesEditorView: View {
    var body: some View {
        IDEScopesView()
            .navigationTitle("Scopes Editor")
            .navigationBarTitleDisplayMode(.inline)
    }
}
