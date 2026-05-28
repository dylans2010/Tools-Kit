import Foundation

public final class ProjectInstallManager: ObservableObject {
    public static let shared = ProjectInstallManager()

    private init() {}

    public func install(from url: URL) throws {
        let data = try Data(contentsOf: url)
        let project = try JSONDecoder().decode(TKProject.self, from: data)

        let newApp = DeveloperApp(
            name: project.metadata.name,
            type: project.type,
            status: .live,
            version: project.metadata.version,
            description: project.metadata.description,
            aboutInfo: "", // Could expand TKProject to include this
            credits: project.metadata.credits,
            socialLinks: project.metadata.socialLinks
        )

        DeveloperPersistentStore.shared.addApp(newApp)
    }
}
