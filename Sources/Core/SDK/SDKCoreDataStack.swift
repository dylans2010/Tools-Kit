import Foundation
import CoreData

public final class SDKCoreDataStack {
    nonisolated(unsafe) public static let shared = SDKCoreDataStack()

    public let container: NSPersistentContainer

    private init() {
        // Since we can't easily create a .xcdatamodeld file in this environment and have it compiled,
        // we'll use a dynamically generated model or stick to the requirement of NSManagedObject subclasses.
        // For the sake of this implementation, we'll define the model in code.

        let model = NSManagedObjectModel()

        // SDKProject Entity
        let projectEntity = NSEntityDescription()
        projectEntity.name = "SDKProject"
        projectEntity.managedObjectClassName = "SDKProjectMO"

        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType

        let nameAttr = NSAttributeDescription()
        nameAttr.name = "name"
        nameAttr.attributeType = .stringAttributeType

        let createdAtAttr = NSAttributeDescription()
        createdAtAttr.name = "createdAt"
        createdAtAttr.attributeType = .dateAttributeType

        projectEntity.properties = [idAttr, nameAttr, createdAtAttr]

        model.entities = [projectEntity]

        container = NSPersistentContainer(name: "SDKModel", managedObjectModel: model)
        container.loadPersistentStores { _, error in
            if let error = error {
                print("CoreData failed to load: \(error.localizedDescription)")
            }
        }
    }

    public var context: NSManagedObjectContext {
        container.viewContext
    }

    public func save() {
        if context.hasChanges {
            try? context.save()
        }
    }
}

@objc(SDKProjectMO)
public class SDKProjectMO: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var createdAt: Date?
}
