import Foundation
import CloudKit

public final class CloudKitSubscriptionManager {
    public static let shared = CloudKitSubscriptionManager()

    private let database: CKDatabase
    private let subscriptionIDPrefix = "com.toolskit.subscription."

    private init() {
        self.database = CloudKitManager.shared.privateDatabase
    }

    public func updateSubscriptions() async {
        do {
            let recordTypes = [
                CloudKitSchema.RecordType.note,
                CloudKitSchema.RecordType.task,
                CloudKitSchema.RecordType.workspace
            ]

            for type in recordTypes {
                try await createSubscription(for: type)
            }
        } catch {
            print("Failed to update CloudKit subscriptions: \(error.localizedDescription)")
        }
    }

    private func createSubscription(for recordType: String) async throws {
        let subscriptionID = subscriptionIDPrefix + recordType.lowercased()

        // Check if subscription already exists
        do {
            _ = try await database.subscription(withID: subscriptionID)
            return // Already exists
        } catch {
            // Continue to create
        }

        let subscription = CKQuerySubscription(
            recordType: recordType,
            predicate: NSPredicate(value: true),
            subscriptionID: subscriptionID,
            options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
        )

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true // Silent push
        subscription.notificationInfo = notificationInfo

        try await database.save(subscription)
    }
}
