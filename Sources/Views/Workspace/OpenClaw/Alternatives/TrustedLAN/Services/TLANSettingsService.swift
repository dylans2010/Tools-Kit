import Foundation
import Observation
@Observable public final class TLANSettingsService {
    public static let shared = TLANSettingsService()
    private let userDefaults = UserDefaults.standard
    public var connectionTimeout: TimeInterval { get { userDefaults.double(forKey: "t_timeout") == 0 ? 30 : userDefaults.double(forKey: "t_timeout") } set { userDefaults.set(newValue, forKey: "t_timeout") } }
    public var approvalTimeout: TimeInterval { get { userDefaults.double(forKey: "a_timeout") == 0 ? 120 : userDefaults.double(forKey: "a_timeout") } set { userDefaults.set(newValue, forKey: "a_timeout") } }
    public var retryCount: Int { get { userDefaults.integer(forKey: "r_count") == 0 ? 3 : userDefaults.integer(forKey: "r_count") } set { userDefaults.set(newValue, forKey: "r_count") } }
    private init() {}
}
