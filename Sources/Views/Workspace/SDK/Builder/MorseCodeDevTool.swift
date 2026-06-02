import SwiftUI

struct MorseCodeDevTool: DevTool {
    let id = "morse-code"
    let name = "Morse Code"
    let category: DevToolCategory = .encoding
    let icon = "waveform.path"
    let description = "Convert text to Morse code and back"

    private static let morseMap: [Character: String] = ["A":".-","B":"-...","C":"-.-.","D":"-..","E":".","F":"..-.","G":"--.","H":"....","I":"..","J":".---","K":"-.-","L":".-..","M":"--","N":"-.","O":"---","P":".--.","Q":"--.-","R":".-.","S":"...","T":"-","U":"..-","V":"...-","W":".--","X":"-..-","Y":"-.--","Z":"--..","0":"-----","1":".----","2":"..---","3":"...--","4":"....-","5":".....","6":"-....","7":"--...","8":"---..","9":"----."]

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Enter text") { input in
            input.uppercased().map { Self.morseMap[$0] ?? String($0) }.joined(separator: " ")
        }
    }
}
