import Foundation
import CloudKit

extension Note {
    func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        let record = CKRecord(recordType: CloudKitSchema.RecordType.note, recordID: recordID)

        record[CloudKitSchema.NoteKeys.title] = title as CKRecordValue
        record[CloudKitSchema.NoteKeys.content] = content as CKRecordValue
        record[CloudKitSchema.NoteKeys.folder] = folder as CKRecordValue
        record[CloudKitSchema.NoteKeys.tags] = tags as CKRecordValue
        record[CloudKitSchema.NoteKeys.isPinned] = (isPinned ? 1 : 0) as CKRecordValue
        record[CloudKitSchema.NoteKeys.createdAt] = createdAt as CKRecordValue
        record[CloudKitSchema.NoteKeys.updatedAt] = updatedAt as CKRecordValue

        return record
    }

    static func fromCKRecord(_ record: CKRecord) -> Note? {
        guard let title = record[CloudKitSchema.NoteKeys.title] as? String,
              let content = record[CloudKitSchema.NoteKeys.content] as? String,
              let idString = record.recordID.recordName as String?,
              let id = UUID(uuidString: idString) else {
            return nil
        }

        let folder = record[CloudKitSchema.NoteKeys.folder] as? String ?? "General"
        let tags = record[CloudKitSchema.NoteKeys.tags] as? [String] ?? []
        let isPinned = (record[CloudKitSchema.NoteKeys.isPinned] as? Int ?? 0) == 1
        let createdAt = record[CloudKitSchema.NoteKeys.createdAt] as? Date ?? Date()
        let updatedAt = record[CloudKitSchema.NoteKeys.updatedAt] as? Date ?? Date()

        return Note(
            id: id,
            title: title,
            content: content,
            folder: folder,
            tags: tags,
            isPinned: isPinned,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
