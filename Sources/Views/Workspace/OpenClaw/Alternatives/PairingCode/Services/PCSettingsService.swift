import Foundation
import Observation

@Observable
public final class PCSettingsService {
    public static let shared = PCSettingsService()
    private let userDefaults = UserDefaults.standard
    public var gatewayURL: String {
        get { userDefaults.string(forKey: "pc_gateway_url") ?? "" }
        set { userDefaults.set(newValue, forKey: "pc_gateway_url") }
    }
    public var attemptLimit: Int {
        get { userDefaults.integer(forKey: "pc_attempt_limit") == 0 ? 10 : userDefaults.integer(forKey: "pc_attempt_limit") }
        set { userDefaults.set(newValue, forKey: "pc_attempt_limit") }
    }
    private init() {}
}
