import Foundation

final class NATOBackend: ObservableObject {
    @Published var output: String = ""

    private let alphabet: [Character: String] = [
        "A": "Alfa", "B": "Bravo", "C": "Charlie", "D": "Delta", "E": "Echo", "F": "Foxtrot", "G": "Golf", "H": "Hotel",
        "I": "India", "J": "Juliett", "K": "Kilo", "L": "Lima", "M": "Mike", "N": "November", "O": "Oscar", "P": "Papa",
        "Q": "Quebec", "R": "Romeo", "S": "Sierra", "T": "Tango", "U": "Uniform", "V": "Victor", "W": "Whiskey", "X": "X-ray",
        "Y": "Yankee", "Z": "Zulu"
    ]

    func translate(_ text: String) {
        self.output = text.uppercased().compactMap { alphabet[$0] }.joined(separator: " ")
    }
}
