import Appwrite

enum AppwriteService {
    private static let defaultEndpoint = "https://fra.cloud.appwrite.io/v1"
    private static let defaultProjectID = "69e24c32003548ff0e2e"

    private static let endpoint = configValue(forKey: "APPWRITE_PUBLIC_ENDPOINT") ?? defaultEndpoint
    private static let projectID = configValue(forKey: "APPWRITE_PROJECT_ID") ?? defaultProjectID

    static let client = Client()
        .setEndpoint(endpoint)
        .setProject(projectID)
    static let account = Account(client)

    private static func configValue(forKey key: String) -> String? {
        guard
            let url = Bundle.main.url(forResource: "Config", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
            let value = plist[key] as? String
        else {
            return nil
        }

        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? nil : trimmedValue
    }
}
