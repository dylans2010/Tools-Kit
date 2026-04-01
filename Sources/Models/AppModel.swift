import Foundation
import SwiftUI

final class AppModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
}
