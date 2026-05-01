import SwiftUI
struct FullEditorView: View {
    let projectID: UUID
    var body: some View {
        #if os(iOS)
        VStack { Text("Professional Media Editor"); AIEditingPanelView() }
        #else
        Text("Media Editor only available on iOS")
        #endif
    }
}