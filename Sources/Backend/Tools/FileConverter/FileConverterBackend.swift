import Foundation
import Combine

class FileConverterBackend: ObservableObject {
    @Published var conversionProgress: Double = 0.0
    @Published var isConverting: Bool = false
    func convert(fileURL: URL, to format: String) {
        isConverting = true
        conversionProgress = 0.0
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            self.conversionProgress += 0.1
            if self.conversionProgress >= 1.0 {
                timer.invalidate()
                self.isConverting = false
            }
        }
    }
}
