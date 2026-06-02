import SwiftUI

struct SwiftUIAnimationSandboxDevTool: DevTool {
    let id = "swiftui-animation-sandbox"
    let name = "SwiftUI Animation Sandbox"
    let category: DevToolCategory = .uiDesign
    let icon = "play.circle"
    let description = "Live preview and tweak SwiftUI animation parameters"

    func render() -> some View {
        SwiftUIAnimationSandboxView()
    }
}

struct SwiftUIAnimationSandboxView: View {
    @State private var animate = false
    @State private var response: Double = 0.5
    @State private var damping: Double = 0.5

    var body: some View {
        VStack {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 100, height: 100)
                .offset(x: animate ? 100 : -100)
                .animation(.spring(response: response, dampingFraction: damping), value: animate)
                .padding(.top, 50)

            Spacer()

            Form {
                Section("Spring Parameters") {
                    HStack {
                        Text("Response")
                        Slider(value: $response, in: 0.1...2.0)
                    }
                    HStack {
                        Text("Damping")
                        Slider(value: $damping, in: 0.1...1.0)
                    }
                }
                Button("Trigger Animation") { animate.toggle() }
            }
        }
    }
}
