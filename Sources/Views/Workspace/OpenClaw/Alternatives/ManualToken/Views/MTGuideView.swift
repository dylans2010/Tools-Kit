import SwiftUI

struct MTGuideView: View {
    var body: some View {
        List {
            Section("What Is This?") {
                Text("Your Mac generates a secure random token. You copy it and paste it into your iPhone.")
            }
            Section("Step-by-Step") {
                Text("1. Open Gateway on Mac.\n2. Pairing -> Manual Token -> Copy.\n3. Paste on iPhone.\n4. Validate.")
            }
        }
        .navigationTitle("Manual Token Guide")
    }
}
