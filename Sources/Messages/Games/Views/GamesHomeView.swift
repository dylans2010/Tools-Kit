import SwiftUI

struct GamesHomeView: View {
    var onSelectGame: (PayloadSubtype) -> Void

    var body: some View {
        List {
            Section("Available Games") {
                Button(action: { onSelectGame(.battleship) }) {
                    Label("Battleship", systemImage: "grid")
                }
                Button(action: { onSelectGame(.basketball) }) {
                    Label("Basketball", systemImage: "sportscourt")
                }
                Button(action: { onSelectGame(.tapRace) }) {
                    Label("Tap Race", systemImage: "timer")
                }
            }
        }
    }
}
