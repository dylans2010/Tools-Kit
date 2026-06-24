import Foundation
import Combine

final class OpenClawMessageBus: ObservableObject {
    static let shared = OpenClawMessageBus()

    private let eventSubject = PassthroughSubject<OpenClawEvent, Never>()
    var events: AnyPublisher<OpenClawEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    func publish(_ event: OpenClawEvent) {
        DispatchQueue.main.async {
            self.eventSubject.send(event)
        }
    }
}
