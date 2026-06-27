import Foundation
import Observation

@Observable @MainActor
public final class PCCodeEntryViewModel {
    public var code: String = ""
    public var isValid: Bool {
        return code.count == 8 && CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: code))
    }
    public init() {}
}
