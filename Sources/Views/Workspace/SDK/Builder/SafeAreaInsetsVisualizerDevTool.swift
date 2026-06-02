import SwiftUI

struct SafeAreaInsetsVisualizerDevTool: DevTool {
    let id = "safe-area-visualizer"
    let name = "Safe Area Insets Visualizer"
    let category: DevToolCategory = .uiDesign
    let icon = "rectangle.inset.filled"
    let description = "Visualize the safe area insets on the current device"

    func render() -> some View {
        GeometryReader { proxy in
            ZStack {
                Color.red.opacity(0.1)
                VStack {
                    Text("Top: \(proxy.safeAreaInsets.top)")
                    Text("Bottom: \(proxy.safeAreaInsets.bottom)")
                    Text("Leading: \(proxy.safeAreaInsets.leading)")
                    Text("Trailing: \(proxy.safeAreaInsets.trailing)")
                }
            }
        }.edgesIgnoringSafeArea(.all)
    }
}
