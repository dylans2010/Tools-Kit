import Foundation

/// Protocol for all system tools.
public protocol SystemTool {
    var name: String { get }
    func execute(input: [String: Any], context: SystemToolContext) async throws -> SystemToolResponse
}

/// Standard context for tool execution.
public struct SystemToolContext: Codable {
    public let workspaceId: String
    public let sessionId: String
    public let timestamp: String

    public init(workspaceId: String, sessionId: String, timestamp: String) {
        self.workspaceId = workspaceId
        self.sessionId = sessionId
        self.timestamp = timestamp
    }

    enum CodingKeys: String, CodingKey {
        case workspaceId = "workspace_id"
        case sessionId = "session_id"
        case timestamp
    }
}

/// Standard response structure for all system tools.
public struct SystemToolResponse: Codable {
    public let tool: String
    public let status: String
    public let requestId: String
    public let input: [String: AnyCodable]
    public let output: [String: AnyCodable]
    public let error: SystemToolError?
    public let context: SystemToolContext

    public init(tool: String, status: String, requestId: String, input: [String: AnyCodable], output: [String: AnyCodable], error: SystemToolError?, context: SystemToolContext) {
        self.tool = tool
        self.status = status
        self.requestId = requestId
        self.input = input
        self.output = output
        self.error = error
        self.context = context
    }

    enum CodingKeys: String, CodingKey {
        case tool
        case status
        case requestId = "request_id"
        case input
        case output
        case error
        case context
    }
}

public struct SystemToolError: Error, Codable {
    public let message: String
    public let code: String

    public init(message: String, code: String) {
        self.message = message
        self.code = code
    }

    public static func missingParameter(_ parameter: String) -> SystemToolError {
        SystemToolError(message: "Missing required parameter: \(parameter)", code: "missing_parameter")
    }

    public static func unsupportedOperation(_ operation: String) -> SystemToolError {
        SystemToolError(message: "Unsupported operation: \(operation)", code: "unsupported_operation")
    }
}

extension SystemTool {
    func successResponse(input: [String: Any], context: SystemToolContext, output: [String: Any]) -> SystemToolResponse {
        SystemToolResponse(
            tool: name,
            status: "success",
            requestId: UUID().uuidString,
            input: input.mapValues { AnyCodable($0) },
            output: output.mapValues { AnyCodable($0) },
            error: nil,
            context: context
        )
    }

    func failureResponse(input: [String: Any], context: SystemToolContext, error: SystemToolError, output: [String: Any] = [:]) -> SystemToolResponse {
        SystemToolResponse(
            tool: name,
            status: "failed",
            requestId: UUID().uuidString,
            input: input.mapValues { AnyCodable($0) },
            output: output.mapValues { AnyCodable($0) },
            error: error,
            context: context
        )
    }

    func requireString(_ input: [String: Any], key: String) throws -> String {
        guard let value = input[key] as? String, !value.isEmpty else {
            throw SystemToolError.missingParameter(key)
        }
        return value
    }

    func toolsWorkingDirectory(from input: [String: Any]) -> URL {
        let provided = (input["workspacePath"] as? String) ?? (input["path"] as? String)
        let basePath = provided?.isEmpty == false ? provided! : FileManager.default.currentDirectoryPath
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: basePath, isDirectory: &isDirectory), isDirectory.boolValue {
            return URL(fileURLWithPath: basePath)
        }
        return URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    }

    func toolsStateURL(fileName: String) -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
    }

    func resolveFileURL(from input: [String: Any], key: String = "path") throws -> URL {
        guard let value = input[key] as? String, !value.isEmpty else {
            throw SystemToolError.missingParameter(key)
        }
        let candidate = URL(fileURLWithPath: value)
        if candidate.path.hasPrefix("/") {
            return candidate
        }
        return toolsWorkingDirectory(from: input).appendingPathComponent(value)
    }

    func enumerateFiles(root: URL, allowedExtensions: Set<String>? = nil) -> [URL] {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var files: [URL] = []
        while let fileURL = enumerator.nextObject() as? URL {
            guard (try? fileURL.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true else { continue }
            if let allowedExtensions {
                let ext = fileURL.pathExtension.lowercased()
                if !allowedExtensions.contains(ext) { continue }
            }
            files.append(fileURL)
        }
        return files
    }

    func loadJSONArray(fileName: String) -> [[String: Any]] {
        let url = toolsStateURL(fileName: fileName)
        guard let data = try? Data(contentsOf: url),
              let object = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }
        return object
    }

    func loadJSONDictionary(fileName: String) -> [String: Any] {
        let url = toolsStateURL(fileName: fileName)
        guard let data = try? Data(contentsOf: url),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return object
    }

    func storeJSON(_ object: Any, fileName: String) throws {
        let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: toolsStateURL(fileName: fileName), options: .atomic)
    }
}

/// Type-erased Codable for handling dynamic JSON objects.
public struct AnyCodable: Codable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if value is NSNull {
            try container.encodeNil()
        } else if let bool = value as? Bool {
            try container.encode(bool)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let string = value as? String {
            try container.encode(string)
        } else if let array = value as? [Any] {
            try container.encode(array.map { AnyCodable($0) })
        } else if let dictionary = value as? [String: Any] {
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        } else {
            let mirror = Mirror(reflecting: value)
            if mirror.displayStyle == .optional {
                if mirror.children.isEmpty {
                    try container.encodeNil()
                } else {
                    let (_, unwrappedValue) = mirror.children.first!
                    try AnyCodable(unwrappedValue).encode(to: encoder)
                }
            } else {
                throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "AnyCodable value cannot be encoded"))
            }
        }
    }
}
