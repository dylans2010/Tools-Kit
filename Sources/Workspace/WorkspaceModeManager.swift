import Foundation
import Combine

final class WorkspaceModeManager: ObservableObject {
    static let shared = WorkspaceModeManager()

    private let key = "workspaceModeEnabled"

    @Published var isWorkspaceModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isWorkspaceModeEnabled, forKey: key)
        }
    }

    private init() {
        if UserDefaults.standard.object(forKey: key) == nil {
            isWorkspaceModeEnabled = true
        } else {
            isWorkspaceModeEnabled = UserDefaults.standard.bool(forKey: key)
        }
    }
}
