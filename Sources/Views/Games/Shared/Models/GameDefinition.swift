import SwiftUI

struct GameDefinition: Identifiable {
    let id: String
    let title: String
    let category: GameCategory
    let iconName: String
    let destination: AnyView
}
