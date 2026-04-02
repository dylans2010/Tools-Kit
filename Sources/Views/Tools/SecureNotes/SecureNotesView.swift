import SwiftUI
struct SecureNotesView: View {
    @StateObject private var backend = SecureNotesBackend()
    var body: some View {
        VStack(spacing: 20) {
            Button("Unlock") {
                backend.auth()
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding()
        .navigationTitle("Secure Notes")
    }
}
struct SecureNotesTool: Tool {
    let name = "Secure Notes"
    let icon = "lock.rectangle"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.advanced
    let description = "Secure notes"
    let isOfflineCapable = true
    let requiresAPI = false
    let isAIEnabled = false
    let complexityLevel = 4
    var view: AnyView { AnyView(SecureNotesView()) }
}
