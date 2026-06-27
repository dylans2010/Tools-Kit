import SwiftUI

struct LAGuideView: View {
    var body: some View {
        List {
            Section("What Is This?") {
                Text("Your iPhone connects to your Mac and asks for approval. Your Mac shows a dialog with your iPhone's details. You click Allow.")
            }
            Section("Step-by-Step") {
                Text("1. Select Mac on iPhone.\n2. Tap Request Access.\n3. Click Allow on Mac NSAlert.")
            }
        }
        .navigationTitle("Local Approval Guide")
    }
}
