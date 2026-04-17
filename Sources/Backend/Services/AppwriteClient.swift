import Appwrite

let client = Client()
    .setEndpoint("https://fra.cloud.appwrite.io/v1")
    .setProject("69e24c32003548ff0e2e")

let account = Account(client)

enum AppwriteService {
    static let client = client
    static let account = account
}
