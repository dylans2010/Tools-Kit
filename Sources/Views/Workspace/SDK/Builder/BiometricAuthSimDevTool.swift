import SwiftUI

struct BiometricAuthSimDevTool: DevTool {
    let id = "biometric-auth-sim"
    let name = "Biometric Auth Simulator"
    let category: DevToolCategory = .security
    let icon = "faceid"
    let description = "Simulate FaceID/TouchID authentication results"

    func render() -> some View {
        BiometricAuthSimView()
    }
}

struct BiometricAuthSimView: View {
    @State private var result = "Waiting..."

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "faceid")
                .font(.system(size: 60))
            Text(result)
                .font(.headline)

            HStack {
                Button("Success") { result = "Authenticated Successfully" }
                    .buttonStyle(.borderedProminent)
                Button("Fail") { result = "Authentication Failed" }
                    .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}
