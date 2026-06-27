
import SwiftUI

struct TLANGuideView: View {
    var body: some View {
        List {
            Section("What Is This?") {
                Text("Trusted LAN Pairing uses your local Wi-Fi network to automatically find your Mac and request permission to connect. Your Mac shows an approval dialog — you click Allow, and your iPhone is permanently trusted.")
            }

            Section("Best For") {
                Label("Offices and shared networks", systemImage: "building.2")
                Label("Strongest verification", systemImage: "shield.checkered")
            }

            Section("Before You Start") {
                Toggle("Same Wi-Fi network", isOn: .constant(true)).disabled(true)
                Toggle("Gateway running on Mac", isOn: .constant(true)).disabled(true)
            }

            Section("Step-by-Step") {
                VStack(alignment: .leading, spacing: 10) {
                    Text("1. Tap 'Trusted LAN Pairing' on the Alternatives screen.")
                    Text("2. Wait for your Mac to appear in the list.")
                    Text("3. Tap your Mac's name.")
                    Text("4. Click 'Allow' on the dialog that appears on your Mac.")
                }
            }

            Section("Troubleshooting") {
                VStack(alignment: .leading) {
                    Text("**No Mac appears**: Check Wi-Fi and Firewall.")
                    Divider()
                    Text("**Hangs on Waiting**: Check for dialog behind windows.")
                }
            }
        }
        .navigationTitle("Trusted LAN Guide")
    }
}
