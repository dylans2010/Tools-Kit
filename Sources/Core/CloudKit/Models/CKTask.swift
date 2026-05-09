import Foundation
import CloudKit

extension WorkspaceTask {
    func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        let record = CKRecord(recordType: CloudKitSchema.RecordType.task, recordID: recordID)

        record[CloudKitSchema.TaskKeys.title] = title as CKRecordValue
        record[CloudKitSchema.TaskKeys.taskDescription] = description as CKRecordValue
        if let dueDate = dueDate {
            record[CloudKitSchema.TaskKeys.dueDate] = dueDate as CKRecordValue
        }
        record[CloudKitSchema.TaskKeys.priority] = priority.rawValue as CKRecordValue
        record[CloudKitSchema.TaskKeys.completed] = (completed ? 1 : 0) as CKRecordValue
        record[CloudKitSchema.TaskKeys.createdAt] = createdAt as CKRecordValue

        return record
    }

    static func fromCKRecord(_ record: CKRecord) -> WorkspaceTask? {
        guard let title = record[CloudKitSchema.TaskKeys.title] as? String,
              let idString = record.recordID.recordName as String?,
              let id = UUID(uuidString: idString) else {
            return nil
        }

        let description = record[CloudKitSchema.TaskKeys.taskDescription] as? String ?? ""
        let dueDate = record[CloudKitSchema.TaskKeys.dueDate] as? Date
        let priorityString = record[CloudKitSchema.TaskKeys.priority] as? String ?? WorkspaceTask.TaskPriority.medium.rawValue
        let priority = WorkspaceTask.TaskPriority(rawValue: priorityString) ?? .medium
        let completed = (record[CloudKitSchema.TaskKeys.completed] as? Int ?? 0) == 1
        let createdAt = record[CloudKitSchema.TaskKeys.createdAt] as? Date ?? Date()

        return WorkspaceTask(
            id: id,
            title: title,
            description: description,
            dueDate: dueDate,
            priority: priority,
            completed: completed,
            createdAt: createdAt
        )
    }
}
