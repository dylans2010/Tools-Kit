import SwiftUI
struct FullEditorView: View {
    let projectID: UUID
    var body: some View {
        #if os(iOS)
        Text("iOS Editor")
        #else
        Text("macOS Fallback")
        #endif
    }
}