import SwiftUI
public struct MTHomeView: View {
    public var body: some View { List { Section("Method") { Text("Manual Token") }; NavigationLink("Paste Token") { MTPasteView() } }.navigationTitle("Manual Token") }
}
