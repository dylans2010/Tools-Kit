import SwiftUI

struct QRGuideView: View {
    var body: some View {
        List {
            Section("What Is This?") {
                Text("Your Mac displays a QR code. Point your iPhone's camera at it. Pairing completes automatically.")
            }
            Section("Step-by-Step") {
                Text("1. Open OpenClaw Gateway on Mac.\n2. Go to Pairing -> Show QR Code.\n3. Grant camera access on iPhone.\n4. Point camera at the QR code.")
            }
        }
        .navigationTitle("QR Code Guide")
    }
}
