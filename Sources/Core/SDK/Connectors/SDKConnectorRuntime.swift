import Foundation
import Combine

public enum ConnectorAuthMethod: String, Codable, CaseIterable {
    case none, apiKey, oauth2, bearer, basic, certificate, webhook
}

public struct ConnectorBinding: Identifiable, Codable {
    public let id: UUID
    public var connectorID: UUID
    public var moduleIdentifier: String
    public var bindingType: BindingType
    public var configuration: [String: String]
    public var isActive: Bool
    public var createdAt: Date

    public enum BindingType: String, Codable, CaseIterable {
        case dataSource, dataSink, eventTrigger, authProvider, configSource
    }

    public init(
        id: UUID = UUID(),
        connectorID: UUID,
        moduleIdentifier: String,
        bindingType: BindingType,
        configuration: [String: String] = [:],
        isActive: Bool = true
    ) {
        self.id = id
        self.connectorID = connectorID
        self.moduleIdentifier = moduleIdentifier
        self.bindingType = bindingType
        self.configuration = configuration
        self.isActive = isActive
        self.createdAt = Date()
    }
}

public struct ConnectorTemplate: Identifiable, Codable {
    public let id: UUID
    public var name: String
    public var description: String
    public var type: ConnectorType
    public var authMethod: ConnectorAuthMethod
    public var defaultEndpoints: [ConnectorEndpointTemplate]
    public var requiredFields: [AuthField]
    public var iconName: String
    public var category: String

    public struct ConnectorEndpointTemplate: Codable {
        public var path: String
        public var method: String
        public var description: String
    }

    public init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        type: ConnectorType,
        authMethod: ConnectorAuthMethod = .apiKey,
        defaultEndpoints: [ConnectorEndpointTemplate] = [],
        requiredFields: [AuthField] = [],
        iconName: String = "link",
        category: String = "General"
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.type = type
        self.authMethod = authMethod
        self.defaultEndpoints = defaultEndpoints
        self.requiredFields = requiredFields
        self.iconName = iconName
        self.category = category
    }
}

@MainActor
public final class SDKConnectorRuntimeBinder: ObservableObject {
    public static let shared = SDKConnectorRuntimeBinder()

    @Published public var bindings: [ConnectorBinding] = []
    @Published public var templates: [ConnectorTemplate] = []
    @Published public var liveStreams: [UUID: Bool] = [:]

    private var streamCancellables: [UUID: AnyCancellable] = [:]
    private let persistenceKey = "sdk_connector_bindings"

    private init() {
        loadBindings()
        registerDefaultTemplates()
    }

    public func bind(connectorID: UUID, to moduleIdentifier: String, type: ConnectorBinding.BindingType, config: [String: String] = [:]) throws -> ConnectorBinding {
        let binding = ConnectorBinding(
            connectorID: connectorID,
            moduleIdentifier: moduleIdentifier,
            bindingType: type,
            configuration: config
        )
        bindings.append(binding)
        saveBindings()

        SDKEventBus.shared.publish(SDKBusEvent(
            channel: "sdk.connectors",
            name: "connector.bound",
            data: ["connectorID": connectorID.uuidString, "module": moduleIdentifier, "type": type.rawValue]
        ))

        return binding
    }

    public func unbind(bindingID: UUID) {
        bindings.removeAll { $0.id == bindingID }
        saveBindings()
    }

    public func bindings(for connectorID: UUID) -> [ConnectorBinding] {
        bindings.filter { $0.connectorID == connectorID }
    }

    public func bindings(for moduleIdentifier: String) -> [ConnectorBinding] {
        bindings.filter { $0.moduleIdentifier == moduleIdentifier }
    }

    public func startLiveStream(connectorID: UUID, interval: TimeInterval = 5.0) {
        liveStreams[connectorID] = true
        streamCancellables[connectorID] = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.emitStreamEvent(connectorID: connectorID)
                }
            }
    }

    public func stopLiveStream(connectorID: UUID) {
        liveStreams[connectorID] = false
        streamCancellables[connectorID]?.cancel()
        streamCancellables.removeValue(forKey: connectorID)
    }

    private func emitStreamEvent(connectorID: UUID) {
        SDKEventBus.shared.publish(SDKBusEvent(
            channel: "sdk.connectors.stream",
            name: "connector.data.tick",
            data: ["connectorID": connectorID.uuidString, "timestamp": ISO8601DateFormatter().string(from: Date())]
        ))
    }

    private func registerDefaultTemplates() {
        templates = [
            ConnectorTemplate(name: "REST API", description: "Generic REST API connector", type: .webhook, authMethod: .bearer, iconName: "network", category: "API"),
            ConnectorTemplate(name: "GraphQL", description: "GraphQL endpoint connector", type: .webhook, authMethod: .bearer, iconName: "point.3.connected.trianglepath.dotted", category: "API"),
            ConnectorTemplate(name: "WebSocket", description: "Real-time WebSocket data stream", type: .webhook, authMethod: .apiKey, iconName: "bolt.horizontal", category: "Streaming"),
            ConnectorTemplate(name: "Firebase", description: "Firebase Realtime Database / Firestore", type: .webhook, authMethod: .apiKey, iconName: "flame", category: "Database"),
            ConnectorTemplate(name: "Slack", description: "Slack workspace integration", type: .webhook, authMethod: .oauth2, iconName: "bubble.left.and.bubble.right", category: "Communication"),
            ConnectorTemplate(name: "MQTT", description: "IoT message broker", type: .webhook, authMethod: .basic, iconName: "sensor.tag.radiowaves.forward", category: "IoT"),
        ]
    }

    private func saveBindings() {
        if let data = try? JSONEncoder().encode(bindings) {
            UserDefaults.standard.set(data, forKey: persistenceKey)
        }
    }

    private func loadBindings() {
        if let data = UserDefaults.standard.data(forKey: persistenceKey),
           let loaded = try? JSONDecoder().decode([ConnectorBinding].self, from: data) {
            bindings = loaded
        }
    }
}
