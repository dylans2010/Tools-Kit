import SwiftUI

public struct MCPResponseRenderer: View {
    public let result: String

    public var body: some View {
        if let data = result.data(using: .utf8) {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                MCPJSONResponseView(json: json)
            } else if let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                MCPTableResponseView(data: array)
            } else if result.contains("![") && result.contains("](") {
                // Heuristic for markdown images
                MCPTextResponseView(text: result)
            } else {
                MCPTextResponseView(text: result)
            }
        } else {
            MCPTextResponseView(text: result)
        }
    }
}

public struct MCPTextResponseView: View {
    public let text: String

    public var body: some View {
        Text(text)
            .font(.body)
            .textSelection(.enabled)
    }
}

public struct MCPJSONResponseView: View {
    public let json: [String: Any]

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("JSON Response")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                Text(prettyPrintedJSON)
                    .font(.system(.caption, design: .monospaced))
                    .padding(10)
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(8)
            }
        }
    }

    private var prettyPrintedJSON: String {
        guard let data = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
              let string = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return string
    }
}

public struct MCPTableResponseView: View {
    public let data: [[String: Any]]

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tabular Data (\(data.count) rows)")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            ScrollView(.horizontal) {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    if let first = data.first {
                        HStack {
                            ForEach(Array(first.keys.sorted()), id: \.self) { key in
                                Text(key.uppercased())
                                    .font(.system(size: 10, weight: .bold))
                                    .frame(width: 120, alignment: .leading)
                                    .padding(8)
                                    .background(Color.primary.opacity(0.1))
                            }
                        }
                    }

                    // Rows
                    ForEach(0..<data.count, id: \.self) { index in
                        HStack {
                            ForEach(Array(data[index].keys.sorted()), id: \.self) { key in
                                Text("\(String(describing: data[index][key] ?? ""))")
                                    .font(.system(size: 10))
                                    .frame(width: 120, alignment: .leading)
                                    .padding(8)
                                    .border(Color.primary.opacity(0.05), width: 0.5)
                            }
                        }
                        .background(index % 2 == 0 ? Color.clear : Color.primary.opacity(0.02))
                    }
                }
            }
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.1), lineWidth: 1))
        }
    }
}

public struct MCPErrorResponseView: View {
    public let error: String

    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)

            Text(error)
                .font(.callout)
                .foregroundStyle(.red)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
}
