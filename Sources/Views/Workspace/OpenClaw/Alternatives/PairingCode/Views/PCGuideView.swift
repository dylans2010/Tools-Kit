import SwiftUI

struct PCGuideView: View {
    var body: some View {
        List {
            Section("What Is This?") {
                Text("Your Mac generates a temporary 8-digit code. Type it into your iPhone. That's it — your devices are paired.")
            }
            Section("Step-by-Step") {
                Text("1. Open OpenClaw Gateway on Mac.\n2. Go to Pairing -> Generate Code.\n3. Type the 8-digit code on iPhone.\n4. Tap Pair.")
            }
        }
        .navigationTitle("Pairing Code Guide")
    }
}
