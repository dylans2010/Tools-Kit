import Foundation
import SwiftUI

/// Engine for managing navigation within SDK-built apps.
public final class SDKNavigationEngine: ObservableObject {
    public static let shared = SDKNavigationEngine()

    @Published public var path = NavigationPath()

    private init() {}

    public func push(_ route: SDKAppRoute) {
        path.append(route)
    }

    public func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
}

public enum SDKAppRoute: Hashable {
    case screen(id: UUID)
    case tool(id: UUID)
    case settings
}
