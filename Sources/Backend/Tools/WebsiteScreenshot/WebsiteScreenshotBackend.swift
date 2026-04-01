import Foundation
import SwiftUI
class WebsiteScreenshotBackend: ObservableObject {
    @Published var shot: UIImage? = nil
    func capture() { shot = UIImage() }
}
