import Foundation
import Combine

@MainActor
public final class SDKConflictResolver: ObservableObject {
    nonisolated(unsafe) public static let shared = SDKConflictResolver()

    @Published public var unresolvedConflicts: [ConflictRecord] = []
    @Published public var resolvedCount: Int = 0

    private init() {}

    public struct ConflictRecord: Identifiable, @unchecked Sendable {
        public let id: UUID
        public let channel: String
        public let localTimestamp: Date
        public let remoteTimestamp: Date
        public let localData: [String: Any]
        public let remoteData: [String: Any]
        public let resolution: Resolution?
    }

    public enum Resolution: String, Sendable {
        case localWins
        case remoteWins
        case merged
    }

    public enum Strategy: Sendable {
        case lastWriterWins
        case localPriority
        case remotePriority
    }

    public func resolve(
        channel: String,
        localData: [String: Any],
        localTimestamp: Date,
        remoteData: [String: Any],
        remoteTimestamp: Date,
        strategy: Strategy = .lastWriterWins
    ) -> [String: Any] {
        let resolution: Resolution
        let result: [String: Any]

        switch strategy {
        case .lastWriterWins:
            if localTimestamp >= remoteTimestamp {
                resolution = .localWins
                result = localData
            } else {
                resolution = .remoteWins
                result = remoteData
            }
        case .localPriority:
            resolution = .localWins
            result = localData
        case .remotePriority:
            resolution = .remoteWins
            result = remoteData
        }

        let record = ConflictRecord(
            id: UUID(),
            channel: channel,
            localTimestamp: localTimestamp,
            remoteTimestamp: remoteTimestamp,
            localData: localData,
            remoteData: remoteData,
            resolution: resolution
        )

        resolvedCount += 1
        if unresolvedConflicts.count > 100 {
            unresolvedConflicts = Array(unresolvedConflicts.suffix(50))
        }
        unresolvedConflicts.append(record)

        SDKLogStore.shared.log(
            "Conflict resolved on '\(channel)' via \(resolution.rawValue)",
            source: "SDKConflictResolver",
            level: .info
        )

        return result
    }
}
