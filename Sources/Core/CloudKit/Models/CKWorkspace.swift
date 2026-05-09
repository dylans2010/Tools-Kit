import Foundation
import CloudKit

extension SDKProject {
    func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        let record = CKRecord(recordType: CloudKitSchema.RecordType.workspace, recordID: recordID)

        record[CloudKitSchema.WorkspaceKeys.name] = name as CKRecordValue
        record[CloudKitSchema.WorkspaceKeys.workspaceDescription] = description as CKRecordValue
        record[CloudKitSchema.WorkspaceKeys.status] = status.rawValue as CKRecordValue
        record[CloudKitSchema.WorkspaceKeys.version] = version as CKRecordValue
        record[CloudKitSchema.WorkspaceKeys.createdAt] = createdAt as CKRecordValue
        record[CloudKitSchema.WorkspaceKeys.updatedAt] = updatedAt as CKRecordValue

        return record
    }

    static func fromCKRecord(_ record: CKRecord) -> SDKProject? {
        guard let name = record[CloudKitSchema.WorkspaceKeys.name] as? String,
              let idString = record.recordID.recordName as String?,
              let id = UUID(uuidString: idString) else {
            return nil
        }

        let description = record[CloudKitSchema.WorkspaceKeys.workspaceDescription] as? String ?? ""
        let statusString = record[CloudKitSchema.WorkspaceKeys.status] as? String ?? SDKProject.ProjectStatus.draft.rawValue
        let status = SDKProject.ProjectStatus(rawValue: statusString) ?? .draft
        let version = record[CloudKitSchema.WorkspaceKeys.version] as? Int ?? 1
        let createdAt = record[CloudKitSchema.WorkspaceKeys.createdAt] as? Date ?? Date()
        let updatedAt = record[CloudKitSchema.WorkspaceKeys.updatedAt] as? Date ?? Date()

        return SDKProject(
            id: id,
            name: name,
            description: description,
            createdAt: createdAt,
            updatedAt: updatedAt,
            version: version,
            status: status
        )
    }
}
