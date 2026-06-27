import SwiftUI
public struct PCHomeView: View {
    public var body: some View {
        List { Section("Method") { Text("Pairing Code").font(.headline); Text("Your Mac generates an 8-digit code. Type it into your iPhone to pair.").font(.subheadline).foregroundStyle(.secondary) }
            Section { NavigationLink("Enter Pairing Code") { PCCodeEntryView() } }
            Section { NavigationLink("User Guide") { PCGuideView() } }
        }.navigationTitle("Pairing Code")
    }
}
