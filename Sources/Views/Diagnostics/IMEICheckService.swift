import Foundation

final class IMEICheckService {
    static let shared = IMEICheckService()
    private init() {}

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 25
        config.timeoutIntervalForResource = 30
        return URLSession(configuration: config)
    }()

    // MARK: - IMEI Validation (Local)

    func luhnValidate(_ imei: String) -> Bool {
        let digits = imei.compactMap { Int(String($0)) }
        guard digits.count == 15 else { return false }
        var sum = 0
        for (index, digit) in digits.enumerated() {
            if index % 2 == 0 {
                sum += digit
            } else {
                let doubled = digit * 2
                sum += doubled > 9 ? doubled - 9 : doubled
            }
        }
        return sum % 10 == 0
    }

    func parseIMEIStructure(_ imei: String) -> IMEIStructure? {
        let digits = imei.filter { $0.isNumber }
        guard digits.count == 15 else { return nil }
        let tac = String(digits.prefix(8))
        let serial = String(digits.dropFirst(8).prefix(6))
        let checkDigit = String(digits.suffix(1))
        return IMEIStructure(
            tac: tac,
            serialNumber: serial,
            checkDigit: checkDigit,
            reportingBody: reportingBody(for: tac)
        )
    }

    private func reportingBody(for tac: String) -> String {
        guard let first2 = Int(String(tac.prefix(2))) else { return "Unknown" }
        switch first2 {
        case 01: return "PTCRB (USA)"
        case 10: return "DIRBS (Pakistan)"
        case 30: return "DIRBS (France)"
        case 35: return "BABT (UK)"
        case 44: return "JATE/TELEC (Japan)"
        case 45: return "KCC (South Korea)"
        case 49: return "BNetzA (Germany)"
        case 50: return "MCMC (Malaysia)"
        case 51: return "NBTC (Thailand)"
        case 52: return "IMDA (Singapore)"
        case 53: return "NTC (Philippines)"
        case 54: return "BTRC (Bangladesh)"
        case 86: return "TAF (China)"
        case 91: return "MSAI (India)"
        default: return "GSMA Registered"
        }
    }

    // MARK: - TAC Database Lookup (Real API)

    func lookupTAC(_ tac: String) async -> TACLookupResult {
        let urlString = "https://api.imeicheck.net/v1/checks"
        guard let url = URL(string: urlString) else {
            return TACLookupResult(brand: nil, model: nil, deviceType: nil, error: "Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["deviceId": tac, "serviceId": 1]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, _) = try await session.data(for: request)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return TACLookupResult(
                    brand: json["brand"] as? String,
                    model: json["model"] as? String ?? json["modelName"] as? String,
                    deviceType: json["deviceType"] as? String ?? json["type"] as? String,
                    error: nil
                )
            }
            return TACLookupResult(brand: nil, model: nil, deviceType: nil, error: "Unable to parse response")
        } catch {
            return TACLookupResult(brand: nil, model: nil, deviceType: nil, error: error.localizedDescription)
        }
    }

    // MARK: - Full IMEI Check (Real API)

    func checkIMEI(_ imei: String, serviceId: Int = 1) async -> IMEICheckResult {
        guard let url = URL(string: "https://api.imeicheck.net/v1/checks") else {
            return IMEICheckResult(success: false, data: [:], error: "Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["deviceId": imei, "serviceId": serviceId]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await session.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return IMEICheckResult(
                    success: httpResponse?.statusCode == 200,
                    data: json,
                    error: nil
                )
            }
            return IMEICheckResult(success: false, data: [:], error: "Unable to parse API response (HTTP \(httpResponse?.statusCode ?? 0))")
        } catch {
            return IMEICheckResult(success: false, data: [:], error: error.localizedDescription)
        }
    }

    // MARK: - Blacklist Check (Real API)

    func checkBlacklist(_ imei: String) async -> BlacklistCheckResult {
        let result = await checkIMEI(imei, serviceId: 12)
        if let error = result.error {
            return BlacklistCheckResult(status: .error, details: [("Error", error)], rawData: result.data)
        }

        var details: [(String, String)] = [("IMEI", imei)]
        var status: BlacklistCheckResult.Status = .unknown

        if let blacklistStatus = result.data["blacklistStatus"] as? String {
            let upper = blacklistStatus.uppercased()
            if upper.contains("CLEAN") || upper.contains("CLEAR") || upper.contains("NOT") {
                status = .clean
            } else if upper.contains("BLACK") || upper.contains("LOST") || upper.contains("STOLEN") || upper.contains("BLOCK") {
                status = .blacklisted
            }
            details.append(("Blacklist Status", blacklistStatus))
        }
        if let model = result.data["model"] as? String { details.append(("Model", model)) }
        if let brand = result.data["brand"] as? String { details.append(("Brand", brand)) }
        if let country = result.data["country"] as? String { details.append(("Country", country)) }
        if let network = result.data["network"] as? String { details.append(("Network", network)) }

        return BlacklistCheckResult(status: status, details: details, rawData: result.data)
    }

    // MARK: - Carrier Lock Check (Real API)

    func checkCarrierLock(_ imei: String) async -> CarrierLockResult {
        let result = await checkIMEI(imei, serviceId: 2)
        if let error = result.error {
            return CarrierLockResult(locked: nil, details: [("Error", error)], rawData: result.data)
        }

        var details: [(String, String)] = [("IMEI", imei)]
        var locked: Bool?

        if let simLock = result.data["simLock"] as? String {
            let upper = simLock.uppercased()
            if upper.contains("UNLOCK") || upper.contains("FREE") { locked = false }
            else if upper.contains("LOCK") { locked = true }
            details.append(("SIM Lock", simLock))
        }
        if let carrier = result.data["carrier"] as? String { details.append(("Carrier", carrier)) }
        if let country = result.data["country"] as? String { details.append(("Country", country)) }
        if let model = result.data["model"] as? String { details.append(("Model", model)) }
        if let network = result.data["network"] as? String { details.append(("Network", network)) }

        return CarrierLockResult(locked: locked, details: details, rawData: result.data)
    }

    // MARK: - Warranty Check (Real API)

    func checkWarranty(_ identifier: String) async -> WarrantyCheckResult {
        let result = await checkIMEI(identifier, serviceId: 6)
        if let error = result.error {
            return WarrantyCheckResult(active: nil, details: [("Error", error)], rawData: result.data)
        }

        var details: [(String, String)] = [("Identifier", identifier)]
        var active: Bool?

        if let warranty = result.data["warrantyStatus"] as? String {
            active = warranty.lowercased().contains("active")
            details.append(("Warranty", warranty))
        }
        if let appleCare = result.data["appleCareEligible"] as? Bool { details.append(("AppleCare Eligible", appleCare ? "Yes" : "No")) }
        if let purchaseDate = result.data["estimatedPurchaseDate"] as? String { details.append(("Est. Purchase", purchaseDate)) }
        if let model = result.data["model"] as? String { details.append(("Model", model)) }
        if let coverage = result.data["coverageType"] as? String { details.append(("Coverage", coverage)) }
        if let expiry = result.data["warrantyExpiry"] as? String { details.append(("Expiry", expiry)) }

        return WarrantyCheckResult(active: active, details: details, rawData: result.data)
    }

    // MARK: - iCloud / Find My Check (Real API)

    func checkiCloudLock(_ imei: String) async -> iCloudLockResult {
        let result = await checkIMEI(imei, serviceId: 3)
        if let error = result.error {
            return iCloudLockResult(locked: nil, details: [("Error", error)], rawData: result.data)
        }

        var details: [(String, String)] = [("IMEI", imei)]
        var locked: Bool?

        if let fmiStatus = result.data["fmiStatus"] as? String {
            let upper = fmiStatus.uppercased()
            if upper.contains("ON") || upper.contains("ACTIVE") || upper.contains("LOCK") { locked = true }
            else if upper.contains("OFF") || upper.contains("CLEAN") || upper.contains("CLEAR") { locked = false }
            details.append(("Find My iPhone", fmiStatus))
        }
        if let lostMode = result.data["lostMode"] as? String { details.append(("Lost Mode", lostMode)) }
        if let model = result.data["model"] as? String { details.append(("Model", model)) }
        if let icloudStatus = result.data["icloudStatus"] as? String { details.append(("iCloud Status", icloudStatus)) }

        return iCloudLockResult(locked: locked, details: details, rawData: result.data)
    }

    // MARK: - Device Info Lookup (Real API)

    func lookupDeviceInfo(_ imei: String) async -> DeviceInfoResult {
        let result = await checkIMEI(imei, serviceId: 1)
        if let error = result.error {
            return DeviceInfoResult(details: [("Error", error)], rawData: result.data)
        }

        var details: [(String, String)] = [("IMEI", imei)]
        let keyMap: [(String, String)] = [
            ("brand", "Brand"), ("model", "Model"), ("modelName", "Model Name"),
            ("deviceType", "Device Type"), ("manufacturer", "Manufacturer"),
            ("country", "Country"), ("network", "Network"),
            ("specifications", "Specifications"), ("releaseDate", "Release Date"),
            ("operatingSystem", "OS"), ("displaySize", "Display"),
            ("resolution", "Resolution"), ("batteryCapacity", "Battery"),
            ("chipset", "Chipset"), ("ram", "RAM"), ("storage", "Storage"),
            ("camera", "Camera"), ("weight", "Weight"), ("dimensions", "Dimensions"),
            ("nfc", "NFC"), ("bluetooth", "Bluetooth"), ("wifi", "WiFi"),
            ("simType", "SIM Type"), ("bands", "Bands")
        ]

        for (key, label) in keyMap {
            if let value = result.data[key] {
                details.append((label, "\(value)"))
            }
        }

        return DeviceInfoResult(details: details, rawData: result.data)
    }

    // MARK: - Network / Country Check (Real API)

    func checkNetwork(_ imei: String) async -> NetworkCheckResult {
        let result = await checkIMEI(imei, serviceId: 4)
        if let error = result.error {
            return NetworkCheckResult(details: [("Error", error)], rawData: result.data)
        }

        var details: [(String, String)] = [("IMEI", imei)]
        let keyMap: [(String, String)] = [
            ("network", "Network"), ("country", "Country"),
            ("carrier", "Carrier"), ("simLock", "SIM Lock"),
            ("blacklistStatus", "Blacklist"), ("model", "Model")
        ]
        for (key, label) in keyMap {
            if let value = result.data[key] { details.append((label, "\(value)")) }
        }

        return NetworkCheckResult(details: details, rawData: result.data)
    }
}

// MARK: - Result Types

struct IMEIStructure {
    let tac: String
    let serialNumber: String
    let checkDigit: String
    let reportingBody: String
}

struct TACLookupResult {
    let brand: String?
    let model: String?
    let deviceType: String?
    let error: String?
}

struct IMEICheckResult {
    let success: Bool
    let data: [String: Any]
    let error: String?
}

struct BlacklistCheckResult {
    enum Status: String {
        case clean = "Clean"
        case blacklisted = "Blacklisted"
        case error = "Error"
        case unknown = "Unknown"
    }
    let status: Status
    let details: [(String, String)]
    let rawData: [String: Any]
}

struct CarrierLockResult {
    let locked: Bool?
    let details: [(String, String)]
    let rawData: [String: Any]
}

struct WarrantyCheckResult {
    let active: Bool?
    let details: [(String, String)]
    let rawData: [String: Any]
}

struct iCloudLockResult {
    let locked: Bool?
    let details: [(String, String)]
    let rawData: [String: Any]
}

struct DeviceInfoResult {
    let details: [(String, String)]
    let rawData: [String: Any]
}

struct NetworkCheckResult {
    let details: [(String, String)]
    let rawData: [String: Any]
}
