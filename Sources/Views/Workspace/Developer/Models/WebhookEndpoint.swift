import Foundation

public enum WebhookEventType: String, Codable, CaseIterable {
    case appInstalled = "app.installed"
    case appUpdated = "app.updated"
    case appDeleted = "app.deleted"
    case userAuthorized = "user.authorized"
    case userRevoked = "user.revoked"
    case paymentSucceeded = "payment.succeeded"
    case paymentFailed = "payment.failed"
}

public struct WebhookDelivery: Identifiable, Codable, Hashable {
    public var id: UUID
    public var timestamp: Date
    public var eventType: WebhookEventType
    public var statusCode: Int
    public var responseSnippet: String
    public var duration: TimeInterval
    public var retryCount: Int
    public var finalFailure: Bool

    public init(id: UUID = UUID(), timestamp: Date = Date(), eventType: WebhookEventType, statusCode: Int, responseSnippet: String = "", duration: TimeInterval = 0, retryCount: Int = 0, finalFailure: Bool = false) {
        self.id = id
        self.timestamp = timestamp
        self.eventType = eventType
        self.statusCode = statusCode
        self.responseSnippet = responseSnippet
        self.duration = duration
        self.retryCount = retryCount
        self.finalFailure = finalFailure
    }
}

public struct WebhookDeliveryStats: Codable, Hashable {
    public var totalDeliveries: Int
    public var successfulDeliveries: Int
    public var failedDeliveries: Int
    public var averageLatency: TimeInterval

    public init(totalDeliveries: Int = 0, successfulDeliveries: Int = 0, failedDeliveries: Int = 0, averageLatency: TimeInterval = 0) {
        self.totalDeliveries = totalDeliveries
        self.successfulDeliveries = successfulDeliveries
        self.failedDeliveries = failedDeliveries
        self.averageLatency = averageLatency
    }
}

public struct WebhookEndpoint: Identifiable, Codable, Hashable {
    public var id: UUID
    public var url: String
    public var subscribedEvents: [WebhookEventType]
    public var isActive: Bool
    public var signingSecretKeyID: UUID
    public var createdAt: Date

    public init(id: UUID = UUID(), url: String, subscribedEvents: [WebhookEventType] = [], isActive: Bool = true, signingSecretKeyID: UUID, createdAt: Date = Date()) {
        self.id = id
        self.url = url
        self.subscribedEvents = subscribedEvents
        self.isActive = isActive
        self.signingSecretKeyID = signingSecretKeyID
        self.createdAt = createdAt
    }
}
