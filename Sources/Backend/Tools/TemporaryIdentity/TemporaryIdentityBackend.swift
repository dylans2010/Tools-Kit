import Foundation

struct TemporaryIdentity: Identifiable, Sendable {
    let id = UUID()
    let fullName: String
    let firstName: String
    let lastName: String
    let email: String
    let phone: String
    let address: String
    let city: String
    let country: String
    let zipCode: String
    let username: String
    let password: String
    let dateOfBirth: String
    let nationality: String
    let generatedAt: Date
}

@MainActor
final class TemporaryIdentityBackend: ObservableObject {
    @Published var currentIdentity: TemporaryIdentity?
    @Published var history: [TemporaryIdentity] = []

    private let firstNames = [
        "Alice","Bob","Clara","David","Emma","Frank","Grace","Henry","Isabella","James",
        "Kate","Liam","Mia","Noah","Olivia","Paul","Quinn","Rachel","Sam","Tara",
        "Uma","Victor","Wendy","Xander","Yasmine","Zara"
    ]
    private let lastNames = [
        "Smith","Johnson","Williams","Brown","Jones","Garcia","Miller","Davis",
        "Rodriguez","Martinez","Hernandez","Lopez","Gonzalez","Wilson","Anderson",
        "Taylor","Thomas","Moore","Jackson","Martin"
    ]
    private let cities = [
        "New York","London","Paris","Berlin","Tokyo","Sydney","Toronto","Amsterdam",
        "Vienna","Barcelona","Stockholm","Oslo","Copenhagen","Zurich","Singapore"
    ]
    private let countries = [
        "United States","United Kingdom","France","Germany","Japan","Australia",
        "Canada","Netherlands","Austria","Spain","Sweden","Norway","Denmark"
    ]
    private let streetNames = [
        "Main St","Oak Ave","Maple Dr","Cedar Ln","Elm Blvd","Park Rd","River Rd",
        "Lake View Dr","Sunset Blvd","Willow Way","Pine St","Birch Ct"
    ]
    private let emailDomains = [
        "proton.me","tutanota.com","guerrillamail.com","mailinator.com","temp.org"
    ]
    private let adjectives = ["swift","bright","calm","bold","wild","sharp","kind","brave"]
    private let nouns = ["wolf","hawk","storm","river","peak","cloud","fox","tide"]

    func generate() {
        let firstName = firstNames.randomElement()!
        let lastName = lastNames.randomElement()!
        let city = cities.randomElement()!
        let country = countries.randomElement()!
        let birthYear = Int.random(in: 1970...2000)
        let birthMonth = Int.random(in: 1...12)
        let birthDay = Int.random(in: 1...28)
        let username = "\(adjectives.randomElement()!)\(nouns.randomElement()!)\(Int.random(in: 10...99))"
        let emailDomain = emailDomains.randomElement()!
        let email = "\(firstName.lowercased()).\(lastName.lowercased())\(Int.random(in: 10...99))@\(emailDomain)"

        let identity = TemporaryIdentity(
            fullName: "\(firstName) \(lastName)",
            firstName: firstName,
            lastName: lastName,
            email: email,
            phone: "+1 \(Int.random(in: 200...999))-\(Int.random(in: 200...999))-\(Int.random(in: 1000...9999))",
            address: "\(Int.random(in: 1...9999)) \(streetNames.randomElement()!)",
            city: city,
            country: country,
            zipCode: String(format: "%05d", Int.random(in: 10000...99999)),
            username: username,
            password: generatePassword(),
            dateOfBirth: String(format: "%04d-%02d-%02d", birthYear, birthMonth, birthDay),
            nationality: country,
            generatedAt: Date()
        )

        currentIdentity = identity
        history.insert(identity, at: 0)
        if history.count > 20 { history.removeLast() }
    }

    func clearHistory() {
        history.removeAll()
    }

    private func generatePassword() -> String {
        let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%"
        return String((0..<16).compactMap { _ in chars.randomElement() })
    }
}
