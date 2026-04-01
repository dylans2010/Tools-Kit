import Foundation
class WebhookTesterBackend: ObservableObject {
    @Published var response = ""
    func send() { response = "Webhook sent" }
}
