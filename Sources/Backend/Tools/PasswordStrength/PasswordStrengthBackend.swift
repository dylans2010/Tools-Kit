import Foundation
class PasswordStrengthBackend: ObservableObject {
    @Published var password = ""
    var strength: Double { password.count > 8 ? 1.0 : 0.5 }
}
