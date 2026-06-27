import Foundation
import Observation

@Observable
public final class MTSettingsService {
    public static let shared = MTSettingsService()
    private let userDefaults = UserDefaults.standard

    public var gatewayHost: String {
        get { userDefaults.string(forKey: "mt_gateway_host") ?? "" }
        set { userDefaults.set(newValue, forKey: "mt_gateway_host") }
    }

    public var gatewayPort: Int {
        get { userDefaults.integer(forKey: "mt_gateway_port") == 0 ? 9876 : userDefaults.integer(forKey: "mt_gateway_port") }
        set { userDefaults.set(newValue, forKey: "mt_gateway_port") }
    }

    private init() {}
}
