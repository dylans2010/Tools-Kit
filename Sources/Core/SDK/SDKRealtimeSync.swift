import Foundation
import Combine

@MainActor
public final class SDKRealtimeSync: ObservableObject {
    public static let shared = SDKRealtimeSync()

    @Published public var activeChannels: Set<String> = []
    @Published public var isConnected = false

    private var channelSubjects: [String: PassthroughSubject<[String: Any], Never>] = [:]
    private var subscriptions: [String: [AnyCancellable]] = [:]
    private var syncTimer: AnyCancellable?
    private let syncInterval: TimeInterval = 5

    private init() {
        startSyncLoop()
    }

    // MARK: - Subscribe

    public func subscribe(channel: String, handler: @escaping ([String: Any]) -> Void) -> AnyCancellable {
        let subject = getOrCreateSubject(for: channel)
        activeChannels.insert(channel)
        isConnected = true

        SDKLogStore.shared.log("Subscribed to channel: \(channel)", source: "SDKRealtimeSync", level: .info)

        return subject
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: handler)
    }

    // MARK: - Broadcast

    public func broadcast(channel: String, data: [String: Any]) {
        if let subject = channelSubjects[channel] {
            subject.send(data)
        }

        SDKEventBridge.shared.emit(type: "realtime.\(channel)", payload: data)
        SDKLogStore.shared.log("Broadcast on channel: \(channel)", source: "SDKRealtimeSync", level: .debug)
    }

    // MARK: - Unsubscribe

    public func unsubscribe(channel: String) {
        subscriptions[channel]?.forEach { $0.cancel() }
        subscriptions.removeValue(forKey: channel)
        channelSubjects.removeValue(forKey: channel)
        activeChannels.remove(channel)

        if activeChannels.isEmpty {
            isConnected = false
        }
    }

    // MARK: - Sync Loop

    private func startSyncLoop() {
        syncTimer = Timer.publish(every: syncInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.performSync()
            }
    }

    private func performSync() {
        for channel in activeChannels {
            NotificationCenter.default.post(
                name: .sdkRealtimeSyncTick,
                object: nil,
                userInfo: ["channel": channel]
            )
        }
    }

    // MARK: - Private

    private func getOrCreateSubject(for channel: String) -> PassthroughSubject<[String: Any], Never> {
        if let existing = channelSubjects[channel] {
            return existing
        }
        let subject = PassthroughSubject<[String: Any], Never>()
        channelSubjects[channel] = subject
        return subject
    }
}

extension NSNotification.Name {
    public static let sdkRealtimeSyncTick = NSNotification.Name("com.toolskit.sdk.realtime.sync.tick")
}
