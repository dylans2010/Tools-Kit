import SwiftUI

class GamesRouter: ObservableObject {
    static let shared = GamesRouter()

    @Published var path = NavigationPath()

    func navigateTo(_ gameID: String) {
        path.append(gameID)
    }

    func goBack() {
        path.removeLast()
    }

    func goToHome() {
        path = NavigationPath()
    }
}
