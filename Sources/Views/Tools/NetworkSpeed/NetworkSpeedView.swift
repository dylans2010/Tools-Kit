import SwiftUI

struct NetworkSpeedView: View {
    @State private var isTesting = false
    @State private var downloadSpeed = "0.0"
    @State private var uploadSpeed = "0.0"

    var body: some View {
        VStack(spacing: 40) {
            HStack(spacing: 40) {
                SpeedMeter(title: "Download", value: downloadSpeed, unit: "Mbps", color: .blue)
                SpeedMeter(title: "Upload", value: uploadSpeed, unit: "Mbps", color: .green)
            }
            .padding(.top, 40)

            Button(action: runTest) {
                if isTesting {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Start Speed Test")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal)

            Spacer()
        }
        .navigationTitle("Network Speed")
    }

    private func runTest() {
        isTesting = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            downloadSpeed = "124.5"
            uploadSpeed = "45.2"
            isTesting = false
        }
    }
}

struct SpeedMeter: View {
    let title: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack {
            Text(title).font(.headline).foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(unit).font(.caption).foregroundColor(.secondary)
        }
    }
}

struct NetworkSpeedTool: Tool {
    let name = "Speed Test"
    let icon = "speedometer"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Measure your current network download and upload speeds"
    let requiresAPI = true
    var view: AnyView { AnyView(NetworkSpeedView()) }
}
