import Foundation

@Observable
final class AppModel {
    var isLoading = false
    var errorMessage: String?
}