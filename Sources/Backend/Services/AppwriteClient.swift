import Appwrite

enum AppwriteService {
    static let client = Client()
        .setEndpoint("https://fra.cloud.appwrite.io/v1")
        .setProject("69e24c32003548ff0e2e")
    static let account = Account(client)
}
