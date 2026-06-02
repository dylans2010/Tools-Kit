import SwiftUI

struct SFSymbolAnimationDevTool: DevTool {
    let id = "sf-symbol-animation"
    let name = "SF Symbol Animation Previewer"
    let category: DevToolCategory = .uiDesign
    let icon = "star.fill"
    let description = "Preview new SF Symbol animations (iOS 17+)"

    func render() -> some View {
        SFSymbolAnimationView()
    }
}

struct SFSymbolAnimationView: View {
    @State private var symbol = "star.fill"
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 40) {
            Image(systemName: symbol)
                .font(.system(size: 80))
                .symbolEffect(.bounce, value: isAnimating)
                .symbolEffect(.pulse, isActive: isAnimating)
                .foregroundStyle(.accent)

            Form {
                TextField("Symbol Name", text: $symbol)
                Button(isAnimating ? "Stop" : "Trigger Bounce/Pulse") {
                    isAnimating.toggle()
                }
            }
        }
        .padding()
    }
}
