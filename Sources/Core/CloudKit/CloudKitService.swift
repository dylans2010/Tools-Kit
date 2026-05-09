import Foundation
import CloudKit

public final class CloudKitService {
    public static let shared = CloudKitService()

    private let manager = CloudKitManager.shared
    private let database: CKDatabase

    private init() {
        self.database = CloudKitManager.shared.privateDatabase
    }

    // MARK: - CRUD Operations

    public func saveRecord(_ record: CKRecord) async throws {
        try await database.save(record)
    }

    public func fetchRecords(ofType type: String, predicate: NSPredicate = NSPredicate(value: true)) async throws -> [CKRecord] {
        let query = CKQuery(recordType: type, predicate: predicate)
        let (results, _) = try await database.records(matching: query)

        var records: [CKRecord] = []
        for (_, result) in results {
            switch result {
            case .success(let record):
                records.append(record)
            case .failure(let error):
                throw error
            }
        }
        return records
    }

    public func updateRecord(_ record: CKRecord) async throws {
        let op = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
        op.savePolicy = .changedKeys

        return try await withCheckedThrowingContinuation { continuation in
            op.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            database.add(op)
        }
    }

    public func deleteRecord(id: CKRecord.ID) async throws {
        try await database.deleteRecord(withID: id)
    }

    public func batchSave(_ records: [CKRecord]) async throws {
        let op = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        op.savePolicy = .allKeys

        return try await withCheckedThrowingContinuation { continuation in
            op.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            database.add(op)
        }
    }
}
