import Foundation

#if canImport(CallKit) && os(iOS)
import CallKit

@MainActor
final class CallKitManager: NSObject, ObservableObject {
    static let shared = CallKitManager()

    var onAnswer: (() -> Void)?
    var onEnd: (() -> Void)?

    private let callController = CXCallController()
    private let providerWrapper = CallKitProvider()
    private var currentCallUUID: UUID?

    private override init() {
        super.init()
        providerWrapper.provider.setDelegate(self, queue: nil)
    }

    func reportIncomingCall(meetingID: String) {
        guard currentCallUUID == nil else { return }
        let callUUID = UUID()
        currentCallUUID = callUUID
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: "Meeting \(meetingID)")
        update.hasVideo = true
        providerWrapper.provider.reportNewIncomingCall(with: callUUID, update: update, completion: nil)
    }

    func reportOutgoingCallStart(meetingID: String) {
        if currentCallUUID == nil {
            currentCallUUID = UUID()
        }
        guard let callUUID = currentCallUUID else { return }
        let handle = CXHandle(type: .generic, value: "Meeting \(meetingID)")
        let action = CXStartCallAction(call: callUUID, handle: handle)
        action.isVideo = true
        let transaction = CXTransaction(action: action)
        callController.request(transaction, completion: nil)
        providerWrapper.provider.reportOutgoingCall(with: callUUID, startedConnectingAt: Date())
    }

    func updateConnected() {
        guard let callUUID = currentCallUUID else { return }
        providerWrapper.provider.reportOutgoingCall(with: callUUID, connectedAt: Date())
    }

    func endCall() {
        guard let callUUID = currentCallUUID else { return }
        let action = CXEndCallAction(call: callUUID)
        let transaction = CXTransaction(action: action)
        callController.request(transaction, completion: nil)
        currentCallUUID = nil
    }
}

extension CallKitManager: CXProviderDelegate {
    nonisolated func providerDidReset(_ provider: CXProvider) {
        Task { @MainActor in
            currentCallUUID = nil
        }
    }

    nonisolated func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        Task { @MainActor in
            onAnswer?()
            action.fulfill()
        }
    }

    nonisolated func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        Task { @MainActor in
            onEnd?()
            currentCallUUID = nil
            action.fulfill()
        }
    }

    nonisolated func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        Task { @MainActor in
            action.fulfill()
        }
    }
}
#else
@MainActor
final class CallKitManager: ObservableObject {
    static let shared = CallKitManager()

    var onAnswer: (() -> Void)?
    var onEnd: (() -> Void)?

    func reportIncomingCall(meetingID: String) {}
    func reportOutgoingCallStart(meetingID: String) {}
    func updateConnected() {}
    func endCall() {}
}
#endif
