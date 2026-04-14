import Foundation

/// Decodes MIME content transfer encodings (quoted-printable, base64) and normalises UTF-8.
struct MailContentDecoder {

    // MARK: - Public API

    /// Auto-detect and decode content based on the Content-Transfer-Encoding header value.
    static func decode(_ content: String, transferEncoding: String) -> String {
        switch transferEncoding.lowercased().trimmingCharacters(in: .whitespaces) {
        case "quoted-printable":
            return decodeQuotedPrintable(content)
        case "base64":
            return decodeBase64(content)
        default:
            return normalizeUTF8(content)
        }
    }

    /// Decode raw data using the supplied MIME charset string, with sensible fallbacks.
    static func decode(data: Data, charset: String) -> String {
        let encoding = stringEncoding(from: charset) ?? .utf8
        return String(data: data, encoding: encoding)
            ?? String(data: data, encoding: .isoLatin1)
            ?? String(data: data, encoding: .ascii)
            ?? "[Could not decode message content]"
    }

    // MARK: - Quoted-Printable Decoding

    /// Decode RFC 2045 quoted-printable encoded content.
    /// Handles soft line breaks (=\r\n or =\n) and =XX hex sequences.
    static func decodeQuotedPrintable(_ input: String) -> String {
        // Remove soft line breaks first
        let softBreakRemoved = input
            .replacingOccurrences(of: "=\r\n", with: "")
            .replacingOccurrences(of: "=\n", with: "")

        var decoded = ""
        var index = softBreakRemoved.startIndex

        while index < softBreakRemoved.endIndex {
            let char = softBreakRemoved[index]
            if char == "=" {
                let next = softBreakRemoved.index(after: index)
                if next < softBreakRemoved.endIndex {
                    let afterNext = softBreakRemoved.index(after: next)
                    if afterNext < softBreakRemoved.endIndex {
                        let hexStr = String(softBreakRemoved[next...afterNext])
                        if let byte = UInt8(hexStr, radix: 16) {
                            decoded.append(Character(UnicodeScalar(byte)))
                            index = softBreakRemoved.index(after: afterNext)
                            continue
                        }
                    }
                }
            }
            decoded.append(char)
            index = softBreakRemoved.index(after: index)
        }

        return normalizeUTF8(decoded)
    }

    // MARK: - Base64 Decoding

    /// Decode a base64 encoded string, returning the UTF-8 string if possible.
    static func decodeBase64(_ input: String) -> String {
        let cleaned = input
            .components(separatedBy: .whitespacesAndNewlines)
            .joined()
        guard
            let data = Data(base64Encoded: cleaned, options: .ignoreUnknownCharacters),
            let decoded = String(data: data, encoding: .utf8)
        else {
            return input
        }
        return decoded
    }

    // MARK: - RFC 2047 Encoded-Word Decoding (email headers)

    /// Decode RFC 2047 encoded words (=?charset?encoding?text?=) in header values.
    static func decodeEncodedWords(_ input: String) -> String {
        let pattern = #"=\?([^?]+)\?([BbQq])\?([^?]*)\?="#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return input }

        var result = input
        let nsInput = input as NSString
        let matches = regex.matches(in: input, range: NSRange(location: 0, length: nsInput.length))

        for match in matches.reversed() {
            guard
                let fullRange    = Range(match.range,       in: input),
                let charsetRange = Range(match.range(at: 1), in: input),
                let encRange     = Range(match.range(at: 2), in: input),
                let textRange    = Range(match.range(at: 3), in: input)
            else { continue }

            let charset      = String(input[charsetRange])
            let encodingChar = String(input[encRange]).uppercased()
            let encodedText  = String(input[textRange])

            let cfEncoding     = CFStringConvertIANACharSetNameToEncoding(charset as CFString)
            let nsEncoding     = CFStringConvertEncodingToNSStringEncoding(cfEncoding)
            let stringEncoding = String.Encoding(rawValue: nsEncoding)

            var decoded: String?

            if encodingChar == "B" {
                // Base64
                if let data = Data(base64Encoded: encodedText, options: .ignoreUnknownCharacters) {
                    decoded = String(data: data, encoding: stringEncoding)
                        ?? String(data: data, encoding: .utf8)
                }
            } else if encodingChar == "Q" {
                // Quoted-printable in header: underscores represent spaces
                let qpText = encodedText.replacingOccurrences(of: "_", with: " ")
                decoded = decodeQuotedPrintable(qpText)
            }

            if let decoded = decoded {
                result = result.replacingCharacters(in: fullRange, with: decoded)
            }
        }

        return result
    }

    // MARK: - UTF-8 Normalisation

    /// Attempt to re-interpret a Latin-1 decoded string as UTF-8 if it contains valid UTF-8 sequences.
    static func normalizeUTF8(_ input: String) -> String {
        // Collect raw byte values from the scalar values (works for latin-1 range)
        let bytes = input.unicodeScalars.compactMap { scalar -> UInt8? in
            guard scalar.value <= 0xFF else { return nil }
            return UInt8(scalar.value)
        }

        guard bytes.count == input.unicodeScalars.count else { return input }

        if let utf8String = String(bytes: bytes, encoding: .utf8) {
            return utf8String
        }
        return input
    }

    private static func stringEncoding(from charset: String) -> String.Encoding? {
        let lower = charset.lowercased()
        switch lower {
        case "utf-8", "utf8":
            return .utf8
        case "iso-8859-1", "latin1", "iso8859-1":
            return .isoLatin1
        case "windows-1252", "cp1252":
            return .windowsCP1252
        case "us-ascii", "ascii":
            return .ascii
        default:
            return nil
        }
    }
}
