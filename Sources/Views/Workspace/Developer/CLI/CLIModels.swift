import SwiftUI

public enum CLICommandCategory: String, Codable, CaseIterable, Identifiable {
    case apps = "Apps & Versions"
    case security = "Security & Auth"
    case operations = "Operations & Infra"
    case resources = "Resources & Analytics"
    case system = "System"

    public var id: String { self.rawValue }

    public var icon: String {
        switch self {
        case .apps: return "app.window.checkerboard"
        case .security: return "lock.shield"
        case .operations: return "cpu"
        case .resources: return "globe"
        case .system: return "terminal"
        }
    }
}

public struct CLICommand: Identifiable {
    public let id = UUID()
    public let name: String
    public let description: String
    public let category: CLICommandCategory
    public let usage: String
    public let action: ([String]) async -> String

    public init(name: String, description: String, category: CLICommandCategory, usage: String, action: @escaping ([String]) async -> String) {
        self.name = name
        self.description = description
        self.category = category
        self.usage = usage
        self.action = action
    }
}

public struct CLICommandOption: Identifiable, Hashable {
    public let id = UUID()
    public let name: String
    public let description: String
    public let category: CLICommandCategory

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    public static func == (lhs: CLICommandOption, rhs: CLICommandOption) -> Bool {
        lhs.name == rhs.name
    }
}

public struct CLIOutput: Identifiable, Equatable {
    public let id = UUID()
    public let text: String
    public let type: OutputType
    public let timestamp = Date()

    public enum OutputType: Equatable {
        case command
        case result
        case error
        case info
        case success
    }
}

public struct CLITheme: Identifiable, Equatable {
    public let id: String
    public let name: String
    public let backgroundColor: Color
    public let textColor: Color
    public let promptColor: Color
    public let errorColor: Color
    public let successColor: Color
    public let infoColor: Color

    public static let classic = CLITheme(
        id: "classic",
        name: "Classic Terminal",
        backgroundColor: .black,
        textColor: .white,
        promptColor: .green,
        errorColor: .red,
        successColor: .green,
        infoColor: .blue
    )

    public static let matrix = CLITheme(
        id: "matrix",
        name: "Matrix",
        backgroundColor: Color(red: 0, green: 0.05, blue: 0),
        textColor: Color(red: 0, green: 0.8, blue: 0),
        promptColor: Color(red: 0, green: 1, blue: 0),
        errorColor: .red,
        successColor: Color(red: 0.4, green: 1, blue: 0.4),
        infoColor: .cyan
    )

    public static let monokai = CLITheme(
        id: "monokai",
        name: "Monokai",
        backgroundColor: Color(red: 0.15, green: 0.15, blue: 0.15),
        textColor: Color(red: 0.9, green: 0.9, blue: 0.9),
        promptColor: Color(red: 0.64, green: 0.89, blue: 0.22),
        errorColor: Color(red: 0.97, green: 0.15, blue: 0.45),
        successColor: Color(red: 0.4, green: 0.85, blue: 0.93),
        infoColor: Color(red: 0.68, green: 0.51, blue: 1)
    )

    public static let ocean = CLITheme(
        id: "ocean",
        name: "Deep Ocean",
        backgroundColor: Color(red: 0.05, green: 0.1, blue: 0.2),
        textColor: Color(red: 0.8, green: 0.9, blue: 1.0),
        promptColor: Color(red: 0.3, green: 0.7, blue: 1.0),
        errorColor: .orange,
        successColor: .mint,
        infoColor: .purple
    )

    public static let themes: [CLITheme] = [.classic, .matrix, .monokai, .ocean]
}
