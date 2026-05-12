import Foundation
import Combine

public struct SDKExposedFeature: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var moduleIdentifier: String
    public var featureName: String
    public var featureDescription: String
    public var inputSchema: [SDKFeatureParameter]
    public var outputType: String
    public var isAsync: Bool
    public var requiredCapabilities: [SDKModuleCapability]
    public var availableAt: Date

    public init(
        id: UUID = UUID(),
        moduleIdentifier: String,
        featureName: String,
        featureDescription: String = "",
        inputSchema: [SDKFeatureParameter] = [],
        outputType: String = "Void",
        isAsync: Bool = false,
        requiredCapabilities: [SDKModuleCapability] = []
    ) {
        self.id = id
        self.moduleIdentifier = moduleIdentifier
        self.featureName = featureName
        self.featureDescription = featureDescription
        self.inputSchema = inputSchema
        self.outputType = outputType
        self.isAsync = isAsync
        self.requiredCapabilities = requiredCapabilities
        self.availableAt = Date()
    }
}

public struct SDKFeatureParameter: Codable, Hashable, Sendable {
    public var name: String
    public var type: String
    public var isRequired: Bool
    public var defaultValue: String?

    public init(name: String, type: String, isRequired: Bool = true, defaultValue: String? = nil) {
        self.name = name
        self.type = type
        self.isRequired = isRequired
        self.defaultValue = defaultValue
    }
}

@MainActor
public final class SDKFeatureExposureManager: ObservableObject {
    public static let shared = SDKFeatureExposureManager()

    @Published public var exposedFeatures: [SDKExposedFeature] = []
    private var executionHandlers: [UUID: ([String: Any]) async throws -> Any] = [:]

    private init() {}

    public func expose(_ feature: SDKExposedFeature, handler: @escaping ([String: Any]) async throws -> Any) {
        exposedFeatures.append(feature)
        executionHandlers[feature.id] = handler

        SDKEventBus.shared.publish(SDKBusEvent(
            channel: "sdk.features",
            name: "feature.exposed",
            data: ["module": feature.moduleIdentifier, "feature": feature.featureName]
        ))
    }

    public func retract(featureID: UUID) {
        exposedFeatures.removeAll { $0.id == featureID }
        executionHandlers.removeValue(forKey: featureID)
    }

    public func retractAll(for moduleIdentifier: String) {
        let ids = exposedFeatures.filter { $0.moduleIdentifier == moduleIdentifier }.map(\.id)
        exposedFeatures.removeAll { $0.moduleIdentifier == moduleIdentifier }
        for id in ids { executionHandlers.removeValue(forKey: id) }
    }

    public func invoke(featureID: UUID, parameters: [String: Any]) async throws -> Any {
        guard let handler = executionHandlers[featureID] else {
            throw SDKError.executionFailed(reason: "No handler registered for feature")
        }

        guard let feature = exposedFeatures.first(where: { $0.id == featureID }) else {
            throw SDKError.executionFailed(reason: "Feature not found")
        }

        for param in feature.inputSchema where param.isRequired {
            guard parameters[param.name] != nil else {
                throw SDKError.validationError(reason: "Missing required parameter: \(param.name)")
            }
        }

        return try await handler(parameters)
    }

    public func features(for moduleIdentifier: String) -> [SDKExposedFeature] {
        exposedFeatures.filter { $0.moduleIdentifier == moduleIdentifier }
    }

    public func features(withCapability capability: SDKModuleCapability) -> [SDKExposedFeature] {
        exposedFeatures.filter { $0.requiredCapabilities.contains(capability) }
    }

    public func search(query: String) -> [SDKExposedFeature] {
        let lowered = query.lowercased()
        return exposedFeatures.filter {
            $0.featureName.lowercased().contains(lowered) ||
            $0.featureDescription.lowercased().contains(lowered) ||
            $0.moduleIdentifier.lowercased().contains(lowered)
        }
    }
}
