import Foundation
import Appwrite
import OSLog

enum AppwriteService: Sendable {
    private static let defaultEndpoint = "https://fra.cloud.appwrite.io/v1"
    private static let defaultProjectID = "69e24c32003548ff0e2e"
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ToolsKit", category: "AppwriteService")

    static let client: Client = {
        let config = loadConfig()
        return Client()
            .setEndpoint(config.endpoint)
            .setProject(config.projectID)
    }()
    static let account = Account(client)

    private static func loadConfig() -> (endpoint: String, projectID: String) {
        guard let url = Bundle.main.url(forResource: "Config", withExtension: "plist") else {
            logger.warning("Config.plist not found; using default Appwrite endpoint and project ID.")
            return (defaultEndpoint, defaultProjectID)
        }

        do {
            let data = try Data(contentsOf: url)
            let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
            let resolvedEndpoint = resolvedConfigValue(
                forKey: "APPWRITE_PUBLIC_ENDPOINT",
                in: plist,
                defaultValue: defaultEndpoint
            )
            let resolvedProjectID = resolvedConfigValue(
                forKey: "APPWRITE_PROJECT_ID",
                in: plist,
                defaultValue: defaultProjectID
            )
            return (
                resolvedEndpoint,
                resolvedProjectID
            )
        } catch {
            logger.error("Failed to parse Config.plist for Appwrite values: \(error.localizedDescription, privacy: .public)")
            return (defaultEndpoint, defaultProjectID)
        }
    }

    private static func resolvedConfigValue(forKey key: String, in plist: [String: Any]?, defaultValue: String) -> String {
        let value = (plist?[key] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.flatMap { $0.isEmpty ? nil : $0 } ?? defaultValue
    }
}
