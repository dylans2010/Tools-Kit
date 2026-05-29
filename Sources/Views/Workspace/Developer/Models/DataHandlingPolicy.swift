import Foundation

public struct DataHandlingPolicy: Identifiable, Codable, Hashable {
    public var id: UUID
    public var appID: UUID
    public var collectedDataTypes: [String]
    public var storageLocation: String
    public var retentionPeriod: String
    public var sharesWithThirdParties: Bool
    public var thirdPartyNames: [String]
    public var deletionPolicyDescription: String
    public var policyDocumentURL: String
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        appID: UUID,
        collectedDataTypes: [String] = [],
        storageLocation: String = "",
        retentionPeriod: String = "",
        sharesWithThirdParties: Bool = false,
        thirdPartyNames: [String] = [],
        deletionPolicyDescription: String = "",
        policyDocumentURL: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.appID = appID
        self.collectedDataTypes = collectedDataTypes
        self.storageLocation = storageLocation
        self.retentionPeriod = retentionPeriod
        self.sharesWithThirdParties = sharesWithThirdParties
        self.thirdPartyNames = thirdPartyNames
        self.deletionPolicyDescription = deletionPolicyDescription
        self.policyDocumentURL = policyDocumentURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
