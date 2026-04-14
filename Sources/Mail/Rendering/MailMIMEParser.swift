import Foundation

// MARK: - Data Types

/// Represents a single decoded MIME part with its content type and raw decoded body.
struct MIMEPart {
    let contentType: String
    let transferEncoding: String
    let content: String
}

/// The result of parsing a MIME message: the best HTML part and the best plain-text part.
struct ParsedMIMEMessage {
    let htmlPart: MIMEPart?
    let textPart: MIMEPart?

    /// Returns the preferred part for display: HTML first, falling back to plain text.
    var preferredPart: MIMEPart? { htmlPart ?? textPart }

    var isEmpty: Bool { htmlPart == nil && textPart == nil }
}

// MARK: - Parser

/// Parses raw IMAP email body responses into structured MIME parts.
/// Supports multipart/alternative, multipart/mixed, and nested multipart structures.
struct MailMIMEParser {

    // MARK: - Public API

    /// Parse a raw IMAP response string and return the best text/html and text/plain parts.
    static func parse(_ raw: String) -> ParsedMIMEMessage {
        // Strip IMAP fetch size literal artifacts like "{1234}\r\n" at the start
        let cleaned = stripIMAPLiteral(raw)

        let headers = extractHeaders(cleaned)
        let contentType = headers["content-type"] ?? "text/plain"

        if contentType.lowercased().contains("multipart") {
            return parseMultipart(cleaned, contentType: contentType)
        } else {
            let body = extractBody(cleaned)
            let encoding = headers["content-transfer-encoding"] ?? "7bit"
            let part = MIMEPart(contentType: contentType, transferEncoding: encoding, content: body)
            if contentType.lowercased().contains("text/html") {
                return ParsedMIMEMessage(htmlPart: part, textPart: nil)
            } else {
                return ParsedMIMEMessage(htmlPart: nil, textPart: part)
            }
        }
    }

    // MARK: - IMAP Literal Strip

    private static func stripIMAPLiteral(_ raw: String) -> String {
        // Remove leading IMAP literal size marker, e.g. "{1234}\r\n" or "{1234}\n"
        let pattern = #"^\{\d+\}\r?\n"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: raw, range: NSRange(raw.startIndex..., in: raw)),
           let range = Range(match.range, in: raw) {
            return String(raw[range.upperBound...])
        }
        return raw
    }

    // MARK: - Multipart Parsing

    private static func parseMultipart(_ raw: String, contentType: String) -> ParsedMIMEMessage {
        guard let boundary = extractBoundary(from: contentType) else {
            return ParsedMIMEMessage(htmlPart: nil, textPart: nil)
        }

        let parts = splitParts(raw, boundary: boundary)
        var htmlPart: MIMEPart?
        var textPart: MIMEPart?

        for part in parts {
            let partHeaders = extractHeaders(part)
            let partContentType = (partHeaders["content-type"] ?? "text/plain").lowercased()
            let encoding = partHeaders["content-transfer-encoding"] ?? "7bit"
            let body = extractBody(part)

            if partContentType.contains("multipart") {
                // Recursively handle nested multipart
                let nested = parseMultipart(part, contentType: partContentType)
                if htmlPart == nil { htmlPart = nested.htmlPart }
                if textPart == nil { textPart = nested.textPart }
            } else if partContentType.contains("text/html") {
                if htmlPart == nil {
                    htmlPart = MIMEPart(contentType: partContentType, transferEncoding: encoding, content: body)
                }
            } else if partContentType.contains("text/plain") {
                if textPart == nil {
                    textPart = MIMEPart(contentType: partContentType, transferEncoding: encoding, content: body)
                }
            }
        }

        return ParsedMIMEMessage(htmlPart: htmlPart, textPart: textPart)
    }

    // MARK: - Header Extraction

    private static func extractHeaders(_ raw: String) -> [String: String] {
        let (headerBlock, _) = splitHeadersAndBody(raw)
        var headers: [String: String] = [:]
        var currentKey = ""
        var currentValue = ""

        for line in headerBlock.components(separatedBy: "\n") {
            let stripped = line.hasSuffix("\r") ? String(line.dropLast()) : line

            if stripped.isEmpty { break }

            if (stripped.hasPrefix(" ") || stripped.hasPrefix("\t")), !currentKey.isEmpty {
                // Header folding continuation
                currentValue += " " + stripped.trimmingCharacters(in: .whitespaces)
            } else if let colonIndex = stripped.firstIndex(of: ":") {
                if !currentKey.isEmpty {
                    headers[currentKey] = currentValue
                }
                currentKey = String(stripped[..<colonIndex]).lowercased()
                currentValue = String(stripped[stripped.index(after: colonIndex)...])
                    .trimmingCharacters(in: .whitespaces)
            }
        }

        if !currentKey.isEmpty {
            headers[currentKey] = currentValue
        }

        return headers
    }

    private static func splitHeadersAndBody(_ raw: String) -> (String, String) {
        if let range = raw.range(of: "\r\n\r\n") {
            return (String(raw[..<range.lowerBound]), String(raw[range.upperBound...]))
        } else if let range = raw.range(of: "\n\n") {
            return (String(raw[..<range.lowerBound]), String(raw[range.upperBound...]))
        }
        return (raw, "")
    }

    private static func extractBody(_ raw: String) -> String {
        splitHeadersAndBody(raw).1
    }

    // MARK: - Boundary Extraction

    private static func extractBoundary(from contentType: String) -> String? {
        let segments = contentType.components(separatedBy: ";")
        for segment in segments {
            let trimmed = segment.trimmingCharacters(in: .whitespaces)
            let lower = trimmed.lowercased()
            if lower.hasPrefix("boundary=") {
                var boundary = String(trimmed.dropFirst("boundary=".count))
                // Remove surrounding quotes if present
                if boundary.hasPrefix("\"") && boundary.hasSuffix("\"") {
                    boundary = String(boundary.dropFirst().dropLast())
                }
                return boundary
            }
        }
        return nil
    }

    // MARK: - Part Splitting

    private static func splitParts(_ raw: String, boundary: String) -> [String] {
        let delimiter    = "--" + boundary
        let endDelimiter = "--" + boundary + "--"

        var parts: [String] = []
        var currentLines: [String] = []
        var inPart = false

        for line in raw.components(separatedBy: "\n") {
            let stripped = line.hasSuffix("\r") ? String(line.dropLast()) : line

            if stripped == endDelimiter {
                if inPart, !currentLines.isEmpty {
                    parts.append(currentLines.joined(separator: "\n"))
                }
                break
            } else if stripped == delimiter {
                if inPart, !currentLines.isEmpty {
                    parts.append(currentLines.joined(separator: "\n"))
                    currentLines = []
                }
                inPart = true
            } else if inPart {
                currentLines.append(line)
            }
        }

        if inPart, !currentLines.isEmpty {
            parts.append(currentLines.joined(separator: "\n"))
        }

        return parts
    }
}
