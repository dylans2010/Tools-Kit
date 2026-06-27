import Foundation
import Observation

@Observable
public final class LASettingsService {
    public static let shared = LASettingsService()
    private let userDefaults = UserDefaults.standard

    public var approvalTimeout: TimeInterval {
        get { userDefaults.double(forKey: "la_approval_timeout") == 0 ? 120.0 : userDefaults.double(forKey: "la_approval_timeout") }
        set { userDefaults.set(newValue, forKey: "la_approval_timeout") }
    }

    public var autoConnect: Bool {
        get { userDefaults.bool(forKey: "la_auto_connect") }
        set { userDefaults.set(newValue, forKey: "la_auto_connect") }
    }

    private init() {}
}
