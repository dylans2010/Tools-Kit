import Foundation
import CoreData

public final class SDKCoreDataStack {
    public static let shared = SDKCoreDataStack()

    public let container: NSPersistentContainer

    private init() {
        let model = NSManagedObjectModel()

        // SDKProject Entity
        let projectEntity = NSEntityDescription()
        projectEntity.name = "SDKProject"
        projectEntity.managedObjectClassName = "SDKProjectMO"

        let projectAttrs: [(String, NSAttributeType)] = [
            ("id", .UUIDAttributeType),
            ("name", .stringAttributeType),
            ("createdAt", .dateAttributeType),
            ("lastBuiltAt", .dateAttributeType),
            ("enabledScopesJSON", .stringAttributeType),
            ("enabledPluginIDsJSON", .stringAttributeType),
            ("enabledToolIDsJSON", .stringAttributeType),
            ("enabledConnectorIDsJSON", .stringAttributeType),
            ("healthStatus", .stringAttributeType)
        ]

        projectEntity.properties = projectAttrs.map { name, type in
            let attr = NSAttributeDescription()
            attr.name = name
            attr.attributeType = type
            attr.isOptional = true
            return attr
        }

        // ConnectorConfig Entity
        let connectorEntity = NSEntityDescription()
        connectorEntity.name = "ConnectorConfig"
        connectorEntity.managedObjectClassName = "ConnectorConfigMO"

        let connectorAttrs: [(String, NSAttributeType)] = [
            ("id", .UUIDAttributeType),
            ("type", .stringAttributeType),
            ("credentialsJSON", .stringAttributeType),
            ("lastSync", .dateAttributeType),
            ("isEnabled", .booleanAttributeType)
        ]

        connectorEntity.properties = connectorAttrs.map { name, type in
            let attr = NSAttributeDescription()
            attr.name = name
            attr.attributeType = type
            attr.isOptional = true
            return attr
        }

        // PluginRecord Entity
        let pluginEntity = NSEntityDescription()
        pluginEntity.name = "PluginRecord"
        pluginEntity.managedObjectClassName = "PluginRecordMO"

        let pluginAttrs: [(String, NSAttributeType)] = [
            ("id", .UUIDAttributeType),
            ("name", .stringAttributeType),
            ("version", .stringAttributeType),
            ("permissionsJSON", .stringAttributeType),
            ("isEnabled", .booleanAttributeType),
            ("installedAt", .dateAttributeType),
            ("toolsJSON", .stringAttributeType),
            ("automationHooksJSON", .stringAttributeType)
        ]

        pluginEntity.properties = pluginAttrs.map { name, type in
            let attr = NSAttributeDescription()
            attr.name = name
            attr.attributeType = type
            attr.isOptional = true
            return attr
        }

        // SDKLogEntry Entity
        let logEntity = NSEntityDescription()
        logEntity.name = "SDKLogEntry"
        logEntity.managedObjectClassName = "SDKLogEntryMO"

        let logAttrs: [(String, NSAttributeType)] = [
            ("id", .UUIDAttributeType),
            ("timestamp", .dateAttributeType),
            ("source", .stringAttributeType),
            ("message", .stringAttributeType),
            ("level", .stringAttributeType)
        ]

        logEntity.properties = logAttrs.map { name, type in
            let attr = NSAttributeDescription()
            attr.name = name
            attr.attributeType = type
            attr.isOptional = true
            return attr
        }

        // SDKAutomationRule Entity
        let ruleEntity = NSEntityDescription()
        ruleEntity.name = "SDKAutomationRule"
        ruleEntity.managedObjectClassName = "SDKAutomationRuleMO"

        let ruleAttrs: [(String, NSAttributeType)] = [
            ("id", .UUIDAttributeType),
            ("name", .stringAttributeType),
            ("triggerJSON", .stringAttributeType),
            ("conditionJSON", .stringAttributeType),
            ("actionJSON", .stringAttributeType),
            ("isEnabled", .booleanAttributeType),
            ("lastRunAt", .dateAttributeType),
            ("runCount", .integer32AttributeType)
        ]

        ruleEntity.properties = ruleAttrs.map { name, type in
            let attr = NSAttributeDescription()
            attr.name = name
            attr.attributeType = type
            attr.isOptional = true
            return attr
        }

        model.entities = [projectEntity, connectorEntity, pluginEntity, logEntity, ruleEntity]

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
            do {
                try context.save()
            } catch {
                print("CoreData save failed: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Managed Object Subclasses

@objc(SDKProjectMO)
public class SDKProjectMO: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var lastBuiltAt: Date?
    @NSManaged public var enabledScopesJSON: String?
    @NSManaged public var enabledPluginIDsJSON: String?
    @NSManaged public var enabledToolIDsJSON: String?
    @NSManaged public var enabledConnectorIDsJSON: String?
    @NSManaged public var healthStatus: String?
}

@objc(ConnectorConfigMO)
public class ConnectorConfigMO: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var type: String?
    @NSManaged public var credentialsJSON: String?
    @NSManaged public var lastSync: Date?
    @NSManaged public var isEnabled: Bool
}

@objc(PluginRecordMO)
public class PluginRecordMO: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var version: String?
    @NSManaged public var permissionsJSON: String?
    @NSManaged public var isEnabled: Bool
    @NSManaged public var installedAt: Date?
    @NSManaged public var toolsJSON: String?
    @NSManaged public var automationHooksJSON: String?
}

@objc(SDKLogEntryMO)
public class SDKLogEntryMO: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var timestamp: Date?
    @NSManaged public var source: String?
    @NSManaged public var message: String?
    @NSManaged public var level: String?
}

@objc(SDKAutomationRuleMO)
public class SDKAutomationRuleMO: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var triggerJSON: String?
    @NSManaged public var conditionJSON: String?
    @NSManaged public var actionJSON: String?
    @NSManaged public var isEnabled: Bool
    @NSManaged public var lastRunAt: Date?
    @NSManaged public var runCount: Int32
}
