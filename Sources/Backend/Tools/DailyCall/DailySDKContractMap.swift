import Foundation
#if canImport(Daily)
import Daily
#endif

enum DailySDKContractMap {
    static let importNamespace = "Daily"
    static let delegateProtocol = "CallClientDelegate"
    static let primaryCallObject = "CallClient"
    static let roomURLType = "URL"
    static let joinSignature = "join(url: URL, token: MeetingToken?, settings: ClientSettingsUpdate?) async throws -> Void"
    static let teardownSequence = "stopLocalAudioLevelObserver -> stopRemoteParticipantsAudioLevelObserver -> leave -> delegate=nil -> release client"
    static let supportsCustomRendering = "Yes via VideoView (commonly wrapped by a SwiftUI UIViewRepresentable, often named DailyVideoView)"
    static let requiredInfoPlistConfiguration = [
        "NSCameraUsageDescription",
        "NSMicrophoneUsageDescription",
        "UIBackgroundModes (array) includes \"audio\""
    ]

    // AGENT DECISION: Official docs endpoint was unreachable in this environment, so signatures are resolved from
    // public Daily iOS integrations (daily-ios-starter-kit and pipecat Daily transport) and guarded with canImport(Daily).
    static let documentationResolutionSource = "Public Daily integration code references"
}

#if canImport(Daily)
typealias DailyPrimaryCallType = CallClient
typealias DailyParticipantType = Participant
typealias DailyVideoTrackType = VideoTrack
#endif
