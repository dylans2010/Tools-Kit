import Foundation
import Security
import CommonCrypto

struct TLSCertificateInfo {
    var subject: String = ""
    var issuer: String = ""
    var validFrom: Date?
    var validTo: Date?
    var sha256Fingerprint: String = ""
    var serialNumber: String = ""
    var isValid: Bool = false
    var daysUntilExpiry: Int = 0

    var expiryStatus: ExpiryStatus {
        if daysUntilExpiry < 0 { return .expired }
        if daysUntilExpiry < 30 { return .expiringSoon }
        return .valid
    }

    enum ExpiryStatus { case valid, expiringSoon, expired }
}

@MainActor
final class TLSInspectorBackend: ObservableObject {
    @Published var domain = "apple.com"
    @Published var isLoading = false
    @Published var certInfo: TLSCertificateInfo?
    @Published var errorMessage = ""

    func inspect() {
        let trimmed = domain.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
        guard !trimmed.isEmpty else { return }

        isLoading = true
        certInfo = nil
        errorMessage = ""

        Task {
            await performInspection(host: trimmed)
        }
    }

    private func performInspection(host: String) async {
        guard let url = URL(string: "https://\(host)") else {
            errorMessage = "Invalid domain"
            isLoading = false
            return
        }

        let delegate = TLSCaptureDelegate()
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.httpMethod = "HEAD"

        do {
            _ = try await session.data(for: request)
        } catch {
            // Still might have captured cert info before error
        }

        if let info = delegate.capturedInfo {
            certInfo = info
        } else {
            errorMessage = "Could not retrieve certificate. Check domain."
        }
        isLoading = false
    }
}

private final class TLSCaptureDelegate: NSObject, URLSessionDelegate, @unchecked Sendable {
    var capturedInfo: TLSCertificateInfo?

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let trust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        var info = TLSCertificateInfo()

        if let certs = SecTrustCopyCertificateChain(trust) as? [SecCertificate], let cert = certs.first {
            let certData = SecCertificateCopyData(cert) as Data
            let sha = certData.sha256Hex
            info.sha256Fingerprint = sha.chunked(by: 2).joined(separator: ":")

            if let summary = SecCertificateCopySubjectSummary(cert) {
                info.subject = summary as String
            }

            if let parsed = CertificateFieldParser.parse(from: certData) {
                if info.issuer.isEmpty { info.issuer = parsed.issuer }
                info.validFrom = parsed.validFrom
                info.validTo = parsed.validTo
                info.serialNumber = parsed.serialNumber
            }

            #if os(macOS)
            let keys = [kSecOIDX509V1IssuerName, kSecOIDX509V1ValidityNotBefore,
                        kSecOIDX509V1ValidityNotAfter, kSecOIDX509V1SerialNumber] as CFArray
            if let values = SecCertificateCopyValues(cert, keys, nil) as? [String: Any] {
                if let issuerDict = values[kSecOIDX509V1IssuerName as String] as? [String: Any],
                   let issuerVal = issuerDict[kSecPropertyKeyValue as String] as? [[String: Any]] {
                    let parts = issuerVal.compactMap { $0[kSecPropertyKeyValue as String] as? String }
                    info.issuer = parts.joined(separator: ", ")
                }
                if let notBefore = values[kSecOIDX509V1ValidityNotBefore as String] as? [String: Any],
                   let ts = notBefore[kSecPropertyKeyValue as String] as? Double {
                    info.validFrom = Date(timeIntervalSinceReferenceDate: ts)
                }
                if let notAfter = values[kSecOIDX509V1ValidityNotAfter as String] as? [String: Any],
                   let ts = notAfter[kSecPropertyKeyValue as String] as? Double {
                    let expiry = Date(timeIntervalSinceReferenceDate: ts)
                    info.validTo = expiry
                    info.daysUntilExpiry = Calendar.current.dateComponents([.day], from: Date(), to: expiry).day ?? 0
                }
                if let serial = values[kSecOIDX509V1SerialNumber as String] as? [String: Any],
                   let serialVal = serial[kSecPropertyKeyValue as String] as? Data {
                    info.serialNumber = serialVal.hexString
                }
            }
            #endif

            if let expiry = info.validTo {
                info.daysUntilExpiry = Calendar.current.dateComponents([.day], from: Date(), to: expiry).day ?? 0
            }

            var trustError: CFError?
            info.isValid = SecTrustEvaluateWithError(trust, &trustError)
        }

        capturedInfo = info
        completionHandler(.useCredential, URLCredential(trust: trust))
    }
}

private struct ParsedCertificateFields {
    let issuer: String
    let validFrom: Date?
    let validTo: Date?
    let serialNumber: String
}

private enum CertificateFieldParser {
    private struct Element {
        let tag: UInt8
        let valueRange: Range<Int>
        let nextOffset: Int
    }

    static func parse(from data: Data) -> ParsedCertificateFields? {
        guard let certificate = readElement(in: data, at: 0), certificate.tag == 0x30 else { return nil }
        guard let tbs = readElement(in: data, at: certificate.valueRange.lowerBound), tbs.tag == 0x30 else { return nil }

        var cursor = tbs.valueRange.lowerBound
        if let version = readElement(in: data, at: cursor), version.tag == 0xA0 {
            cursor = version.nextOffset
        }

        guard let serial = readElement(in: data, at: cursor), serial.tag == 0x02 else { return nil }
        let serialNumber = Data(data[serial.valueRange]).hexString
        cursor = serial.nextOffset

        guard let signature = readElement(in: data, at: cursor), signature.tag == 0x30 else { return nil }
        cursor = signature.nextOffset

        guard let issuerName = readElement(in: data, at: cursor), issuerName.tag == 0x30 else { return nil }
        let issuer = parseName(in: data, range: issuerName.valueRange)
        cursor = issuerName.nextOffset

        guard let validity = readElement(in: data, at: cursor), validity.tag == 0x30 else {
            return ParsedCertificateFields(issuer: issuer, validFrom: nil, validTo: nil, serialNumber: serialNumber)
        }
        let (validFrom, validTo) = parseValidity(in: data, range: validity.valueRange)

        return ParsedCertificateFields(
            issuer: issuer,
            validFrom: validFrom,
            validTo: validTo,
            serialNumber: serialNumber
        )
    }

    private static func readElement(in data: Data, at offset: Int) -> Element? {
        guard offset + 1 < data.count else { return nil }
        let tag = data[offset]
        var lengthOffset = offset + 1
        let lengthByte = data[lengthOffset]
        lengthOffset += 1

        let length: Int
        if lengthByte & 0x80 == 0 {
            length = Int(lengthByte)
        } else {
            let byteCount = Int(lengthByte & 0x7F)
            guard byteCount > 0, lengthOffset + byteCount <= data.count else { return nil }
            var result = 0
            for i in 0..<byteCount {
                result = (result << 8) | Int(data[lengthOffset + i])
            }
            length = result
            lengthOffset += byteCount
        }

        let valueStart = lengthOffset
        let valueEnd = valueStart + length
        guard valueEnd <= data.count else { return nil }
        return Element(tag: tag, valueRange: valueStart..<valueEnd, nextOffset: valueEnd)
    }

    private static func parseValidity(in data: Data, range: Range<Int>) -> (Date?, Date?) {
        var cursor = range.lowerBound
        var dates: [Date] = []
        while cursor < range.upperBound, dates.count < 2 {
            guard let element = readElement(in: data, at: cursor), element.nextOffset <= range.upperBound else { break }
            if (element.tag == 0x17 || element.tag == 0x18),
               let raw = String(data: Data(data[element.valueRange]), encoding: .ascii),
               let date = parseTime(raw, tag: element.tag) {
                dates.append(date)
            }
            cursor = element.nextOffset
        }
        return (dates.first, dates.count > 1 ? dates[1] : nil)
    }

    private static func parseTime(_ value: String, tag: UInt8) -> Date? {
        let formats: [String]
        if tag == 0x17 {
            formats = ["yyMMddHHmmss'Z'", "yyMMddHHmm'Z'"]
        } else {
            formats = ["yyyyMMddHHmmss'Z'", "yyyyMMddHHmm'Z'"]
        }
        for format in formats {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = format
            if let date = formatter.date(from: value) { return date }
        }
        return nil
    }

    private static func parseName(in data: Data, range: Range<Int>) -> String {
        var cursor = range.lowerBound
        var components: [String] = []
        while cursor < range.upperBound {
            guard let set = readElement(in: data, at: cursor), set.tag == 0x31, set.nextOffset <= range.upperBound else { break }
            var setCursor = set.valueRange.lowerBound
            while setCursor < set.valueRange.upperBound {
                guard let attribute = readElement(in: data, at: setCursor), attribute.tag == 0x30, attribute.nextOffset <= set.valueRange.upperBound else { break }
                if let parsed = parseAttribute(in: data, range: attribute.valueRange) {
                    components.append(parsed)
                }
                setCursor = attribute.nextOffset
            }
            cursor = set.nextOffset
        }
        return components.joined(separator: ", ")
    }

    private static func parseAttribute(in data: Data, range: Range<Int>) -> String? {
        var cursor = range.lowerBound
        guard let oidElement = readElement(in: data, at: cursor), oidElement.tag == 0x06, oidElement.nextOffset <= range.upperBound else { return nil }
        let oid = decodeOID(Data(data[oidElement.valueRange]))
        cursor = oidElement.nextOffset

        guard let valueElement = readElement(in: data, at: cursor), valueElement.nextOffset <= range.upperBound else { return nil }
        guard let value = decodeString(Data(data[valueElement.valueRange])) else { return nil }

        let key: String
        switch oid {
        case "2.5.4.3": key = "CN"
        case "2.5.4.6": key = "C"
        case "2.5.4.7": key = "L"
        case "2.5.4.8": key = "ST"
        case "2.5.4.10": key = "O"
        case "2.5.4.11": key = "OU"
        default: key = oid
        }
        return "\(key)=\(value)"
    }

    private static func decodeOID(_ data: Data) -> String {
        guard let first = data.first else { return "" }
        var values = [Int(first / 40), Int(first % 40)]
        var accumulator = 0
        for byte in data.dropFirst() {
            accumulator = (accumulator << 7) | Int(byte & 0x7F)
            if byte & 0x80 == 0 {
                values.append(accumulator)
                accumulator = 0
            }
        }
        return values.map(String.init).joined(separator: ".")
    }

    private static func decodeString(_ data: Data) -> String? {
        if let utf8 = String(data: data, encoding: .utf8), !utf8.isEmpty { return utf8 }
        if let ascii = String(data: data, encoding: .ascii), !ascii.isEmpty { return ascii }
        if let latin1 = String(data: data, encoding: .isoLatin1), !latin1.isEmpty { return latin1 }
        return nil
    }
}

private extension Data {
    var sha256Hex: String {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        withUnsafeBytes { _ = CC_SHA256($0.baseAddress, CC_LONG(count), &digest) }
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}

private extension String {
    func chunked(by size: Int) -> [String] {
        stride(from: 0, to: count, by: size).map {
            let start = index(startIndex, offsetBy: $0)
            let end = index(start, offsetBy: min(size, count - $0))
            return String(self[start..<end])
        }
    }
}
