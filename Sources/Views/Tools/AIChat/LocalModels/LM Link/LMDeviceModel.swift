import Foundation

enum LMDeviceStatus: String, Codable {
    case online
    case offline
    case linking
}

struct LMDevice: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    let ipAddress: String
    let port: Int
    var status: LMDeviceStatus
    var lastSeen: Date
    var models: [LMModel] = []

    var baseURL: String {
        return "http://\(ipAddress):\(port)"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: LMDevice, rhs: LMDevice) -> Bool {
        lhs.id == rhs.id
    }
}

struct LMModel: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let architecture: String?
    let contextLength: Int?

    init(id: String, name: String? = nil, architecture: String? = nil, contextLength: Int? = nil) {
        self.id = id
        self.name = name ?? id
        self.architecture = architecture
        self.contextLength = contextLength
    }
}

struct LMModelsResponse: Codable {
    let data: [LMModelData]
}

struct LMModelData: Codable {
    let id: String
    let object: String
    let owned_by: String?
}
