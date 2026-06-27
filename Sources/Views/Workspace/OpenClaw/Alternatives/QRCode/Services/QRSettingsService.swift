import Foundation
import Observation

@Observable
public final class QRSettingsService {
    public static let shared = QRSettingsService()
    private let userDefaults = UserDefaults.standard

    public var autoConnect: Bool {
        get { userDefaults.bool(forKey: "qr_auto_connect") }
        set { userDefaults.set(newValue, forKey: "qr_auto_connect") }
    }

    private init() {}
}
